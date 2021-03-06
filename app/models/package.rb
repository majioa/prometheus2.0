# frozen_string_literal: true

class Package < ApplicationRecord
   class AlreadyExistError < StandardError; end
   class SourceIsntFound < StandardError; end
   class AttachedNewBranchError < StandardError; end
   class InvalidMd5SumError < StandardError; end

   enum repocop_status: RepocopNote.statuses.keys

   belongs_to :group
   belongs_to :src, class_name: 'Package::Src', optional: true
   belongs_to :builder, class_name: 'Maintainer', inverse_of: :rpms, counter_cache: :srpms_count

   has_one :rpm
   has_one :branch_path, through: :rpm
   has_one :branch, through: :branch_path
   has_one :task_rpm, primary_key: :md5, foreign_key: :md5
   has_one :task, through: :task_rpm

   has_many :rpms, inverse_of: :package
   has_many :all_rpms, -> { unscope(where: :obsoleted_at) }, class_name: 'Rpm', dependent: :destroy
   has_many :branch_paths, through: :rpms
   has_many :branches, through: :branch_paths
   has_many :repocop_notes
   has_many :descriptions, class_name: "Lorem::Description"
   has_many :summaries, class_name: "Lorem::Summary"
   has_many :exercises, primary_key: :name, foreign_key: :pkgname
   has_many :repos, through: :exercises

   scope :ordered, -> { order('packages.buildtime DESC') }
   scope :by_name, ->(name) { where(name: name) }
   scope :published, -> { joins(:branch_paths).merge(BranchPath.published) }
   scope :src, -> { where(arch: 'src') }
   scope :built, -> { where.not(arch: 'src') }
   scope :for_maintainer, ->(maintainer) { where(name: maintainer.affected_repo_names) }
   scope :in_branch, ->(branches) do
      branches.present? && joins(:branch_paths).where(branch_paths: {branch_id: branches}) || self
   end
   scope :by_branch_slug, ->(slug) do
      if slug.blank?
         joins(:branches).where(branches: { slug: Branch.select(:slug) })
      else
         joins(:branches).where(branches: { slug: slug })
      end
   end
   scope :by_arch, ->(arch_in) do
      if arch_in.blank?
         all
      else
         subquery = "SELECT DISTINCT src_id FROM packages WHERE packages.arch IN (?)"

         arches = [ arch_in, 'noarch' ]
         self.from('packages')
             .where("packages.id IN (#{subquery})", arches)
             .joins("INNER JOIN branch_paths AS branch_paths_a
                            ON rpms.branch_path_id = branch_paths_a.id")
             .merge(BranchPath.for(arch_in))
             .select("packages.*")
      end
   end
   scope :by_evr, ->(evr) do
      if evr.blank?
         self
      else
         evrs = evr.split(/[:\-]/)

         if evrs.size == 2
            where(version: evrs[0], release: evrs[1])
         else
            where(epoch: evrs[0], version: evrs[1], release: evrs[2])
         end
      end
   end
   scope :by_source, ->(packages) do
      self.where(src_id: packages)
          .order(Arel.sql("(CASE packages.arch WHEN 'src' THEN 0 ELSE 1 END)"))
   end
   scope :query, ->(text_in) do
      text = text_in.to_s.split(/(?<=\w)[ \._\-]+(?=\w)/).reject { |x| x.blank? }.join(" & ")
      tqs_from = Arel.sql(sanitize_sql_array(["packages, to_tsquery(?) AS q", text]))
      tqs_select = Arel.sql(sanitize_sql_array(["DISTINCT name, src_id, CASE packages.name WHEN ? THEN 1 ELSE ts_rank_cd(tsv, q, 32) END AS rank", text_in]))
      tqs = Package.from(tqs_from).where("tsv @@ q").select(tqs_select)

      qs_select = Arel.sql("packages.name,
                   MAX(tqs.rank) AS rank,
                   array_agg(DISTINCT packages.id) AS src_ids,
                   jsonb_object_agg(DISTINCT packages.buildtime,
                                             CASE
                                             WHEN packages.epoch IS NULL
                                             THEN ''
                                             ELSE packages.epoch || ':'
                                             END || packages.version || '-' || packages.release
                                    ) AS evrbes,
                   jsonb_object_agg(DISTINCT packages.buildtime, qs_branches.slug) AS slugs")
      qs_join = Arel.sql("INNER JOIN rpms AS qs_rpms ON qs_rpms.package_id = packages.id AND qs_rpms.obsoleted_at IS NULL
                          INNER JOIN branch_paths AS qs_branch_paths ON qs_branch_paths.id = qs_rpms.branch_path_id
                          INNER JOIN branches AS qs_branches ON qs_branches.id = qs_branch_paths.branch_id
                          INNER JOIN (#{tqs.to_sql}) AS tqs ON tqs.src_id = packages.id")
      qs = Package.src
                  .joins(qs_join)
                  .group(:name)
                  .order(:name)
                  .select(qs_select)

      self.joins(:branch, "INNER JOIN (#{qs.to_sql}) AS qs ON packages.id = ANY (qs.src_ids)")
          .order("qs.rank DESC, packages.name, branches.order_id DESC")
          .select("packages.*, branches.slug, qs.rank, qs.evrbes, qs.slugs")
   end
   scope :search, ->(text_in) do
      text_re = text_in.gsub(/[-.{}\(\)^\[\]\+\\\/$]/) {|x| '\\' + x }.gsub(/[*?]*?\*[*?]*/, '.*').gsub(/\?/, '.')
      wsqls = %w(name description).map { |c| Arel.sql(sanitize_sql_array(["packages.#{c} ~ ?", "^#{text_re}$"])) }
      where(wsqls.join(" OR "))
   end
   scope :aggregated, ->(select = [ "packages.name" ]) do
         qs_select = Arel.sql("packages.name,
                      array_agg(DISTINCT packages.id) AS src_ids,
                      jsonb_object_agg(DISTINCT packages.buildtime,
                                                CASE
                                                WHEN packages.epoch IS NULL
                                                THEN ''
                                                ELSE packages.epoch || ':'
                                                END || packages.version || '-' || packages.release
                                       ) AS evrbes,
                      jsonb_object_agg(DISTINCT packages.buildtime, qs_branches.slug) AS slugs")
         qs_join = Arel.sql("INNER JOIN rpms AS qs_rpms ON qs_rpms.package_id = packages.id AND qs_rpms.obsoleted_at IS NULL
                             INNER JOIN branch_paths AS qs_branch_paths ON qs_branch_paths.id = qs_rpms.branch_path_id
                             INNER JOIN branches AS qs_branches ON qs_branches.id = qs_branch_paths.branch_id")
         wheres = where_clause.send(:predicates).reduce {|res, c| res.and(c) }
         qs = Package.joins([qs_join]|joins_values)
                     .where(wheres)
                     .group(:name)
                     .order(:name)
                     .select(qs_select)

         joins(:branch, "INNER JOIN (#{qs.to_sql}) AS qs ON packages.id = ANY (qs.src_ids)")
        .order("packages.name, branches.order_id DESC")
        .select("DISTINCT on(#{[ select ].flatten.join(",")}) packages.*, branches.slug, qs.evrbes, qs.slugs")
   end
   scope :counted_arches_for, ->(branch) do
      ases = Package.joins(:branches)
                    .where(arch: BranchPath::PHYS_ARCHES, branches: { slug: branch.slug })
                    .select("DISTINCT ON (packages.arch, packages.src_id) packages.arch, packages.src_id")

      self.joins("INNER JOIN (#{ases.to_sql}) as ases ON ases.src_id = packages.id")
          .group("ases.arch")
          .order("ases.arch ASC")
          .select("ases.arch, count(ases.src_id) AS count")
   end
   scope :uniq_named, -> do
      self.select("DISTINCT ON(packages.buildtime,packages.name, packages.epoch, packages.version, packages.release) packages.*")
          .order("packages.buildtime DESC, packages.name, packages.epoch, packages.version, packages.release")
   end
   scope :q, ->(text_in) do
      if text_in.blank?
         all
      elsif /[\*\?]/ =~ text_in
         search(text_in)
      else
         query(text_in)
      end
   end

   singleton_class.send(:alias_method, :a, :by_arch)
   singleton_class.send(:alias_method, :b, :by_branch_slug)

   validates_presence_of :buildtime, :md5, :group, :builder, :name, :arch, :builder

   accepts_nested_attributes_for :descriptions, reject_if: :all_blank, allow_destroy: true
   accepts_nested_attributes_for :summaries, reject_if: :all_blank, allow_destroy: true

   def to_param
      name
   end

   def fullname # TODO move in favor of evrb
      [ name, evr ].join('-')
   end

   def evrb
      [epoch, "#{version}-#{release}-#{buildtime.to_i}"].compact.join(":")
   end

   def evr
      [epoch, "#{version}-#{release}"].compact.join(":")
   end

   def newer_gear
      [ gear, srpm_git ].compact.sort_by { |g| g.changed_at }.last
   end

   def first_presented_filepath
      rpms.map do |rpm|
         File.file?(filepath = rpm.filepath) && filepath || nil
      end.compact.first
   end

   # props
   def archive_uri
      if branch.archive_uri
         File.join(branch.archive_uri, name[0], name)
      end
   end

   def branch_slug
      read_attribute(:slug) || branch.slug
   end

   def count
      read_attribute(:count)
   end

   def rpm_in_branch branch
      rpms.joins(:branch_path).where(branch_paths: { branch_id: branch.id }).first
   end

   def was_rebuilt?
      buildtime && rebuilt_at.present? && rebuilt_at != buildtime
   end

   def rebuilt_at
     @rebuilt_at ||= Package::Src.where(name: name, version: version, release: release, epoch: nil)
                                 .where.not(id: id)
                                 .order(buildtime: :desc)
                                 .first
                                 &.buildtime
   end

   def self.source
      @source ||= self.to_s.split('::').last
   end

   def self.import branch_path, rpm
      if !rpm.has_valid_md5?
         raise InvalidMd5SumError
      end

      filepath = File.join(branch_path.path, rpm.file)
      package = Package.find_or_initialize_by(md5: rpm.md5) do |package|
         package.name = rpm.name
         package.version = rpm.version
         package.release = rpm.release
         package.epoch = rpm.epoch
         package.arch = rpm.arch
         package.buildhost = rpm.buildhost

         package.summary = rpm.summary
         package.license = rpm.license
         package.url = rpm.url
         package.description = rpm.description
         package.vendor = rpm.vendor
         package.distribution = rpm.distribution
         package.buildtime = rpm.buildtime
         package.size = rpm.size

         package.builder = Maintainer.import_from_changelogname(rpm.change_log.first&.[](1))

         BranchingMaintainer.find_or_create_by!(maintainer: package.builder,
                                                branch: branch_path.branch)

         m = Maintainer.import_from_changelogname(rpm.packager)

         BranchingMaintainer.find_or_create_by!(maintainer: m,
                                                branch: branch_path.branch)

         package.type = rpm.sourcerpm && 'Package::Built' || 'Package::Src'

         package.rpms << Rpm.new(branch_path: branch_path,
                                 filename: rpm.filename)

         # russian zone
         rpm_ru = Rpm::Base.new(rpm.file, "ru_RU.UTF-8")

         if rpm_ru.summary.present? && rpm_ru.summary != rpm.summary
            package.summaries << Lorem::Summary.new(text: rpm_ru.summary, codepage: "ru_RU.UTF-8")
         end

         if rpm_ru.description.present? && rpm_ru.description != rpm.description
            package.descriptions << Lorem::Description.new(text: rpm_ru.description, codepage: "ru_RU.UTF-8")
         end

         if rpm.sourcerpm
            spkgs = Rpm.where(filename: rpm.sourcerpm,
                              branch_path_id: branch_path.branch.branch_paths.src.select(:id)).src
            if spkgs.blank?
               spkgs = Rpm.where(filename: rpm.sourcerpm,
                                 branch_path_id: branch_path.source_path_id).src
            end

            package.src_id = spkgs.first&.package_id
         end
      end

      if rpm.sourcerpm
         if spkg_id = Rpm.where(filename: rpm.sourcerpm, branch_path_id: branch_path.source_path).first&.package_id
            package.src_id = spkg_id
         end

         if !package.src_id
            raise SourceIsntFound.new(rpm.sourcerpm)
         end
      end

      if !package.group
         group_name = rpm.group
         branch_group = ImportBranchGroup.new(branch: branch_path.branch, group_name: group_name).do
         package.group = branch_group.group
         package.groupname = group_name
      end

      if package.new_record?
         package.save!
         if rpm.sourcerpm
            #Provide.import_provides(rpm, package)
            #Require.import_requires(rpm, package)
            #Conflict.import_conflicts(rpm, package)
            #Obsolete.import_obsoletes(rpm, package)
         else
            Changelog.import_from(rpm, package)
            Specfile.import(rpm, package)
            Patch.import(rpm, package)
            Source.import_from(rpm, package)
         end
      else
         if package.changed?
            package.save!
         end

         r = Rpm.unscope(:where)
                .find_or_initialize_by(branch_path_id: branch_path.id,
                                       filename: rpm.filename,
                                       package_id: package.id)

         if !r.obsoleted_at && r.persisted?
            raise AlreadyExistError
         else
            r.update!(obsoleted_at: nil) # NOTE sometimes rpms are appeared in a branch with the samecreds but obsoleted....

            raise AttachedNewBranchError
         end
      end

      info("IMPORT: file '#{ filepath }' imported to branch #{branch_path.branch.name}")
      package

   rescue AttachedNewBranchError
      info("IMPORT: file '#{ filepath }' added to branch #{branch_path.branch.name}")
      package

   rescue AlreadyExistError
      info("IMPORT: file '#{ filepath }' exists in #{branch_path.branch.name}... skipping")
      package
   end

   def self.info *text
      Rails.logger.info(text.join)
   end

   def self.error *text
      Rails.logger.error(text.join)
   end

   def self.import_all branch
      time = Time.zone.now
      Rails.logger.info "IMPORT: at #{time} for #{branch.name} in"

      affected = {
         branches: [],
         groups: [],
      }

      branch.branch_paths.send(source.downcase).active.each do |branch_path|
         next if !File.directory?(branch_path.path)

         Rails.logger.info "IMPORT: Branch path #{branch_path.path}"

         mins = (time - branch_path.imported_at + 59).to_i / 60
         find = "find #{branch_path.path} -name '#{branch_path.glob}' | sed 's|#{branch_path.path}/*||' | sort"
         Rails.logger.info "IMPORT: search with: #{find}"

         current_list = `#{find}`.split("\n")
         stored_list = branch_path.rpms.where(filename: current_list).select(:filename).pluck(:filename)
         Rails.logger.info "IMPORT: found in path: #{current_list.size}, and in database #{stored_list.count}"

         nonexist_list = current_list - stored_list
         Rails.logger.info "IMPORT: will be imported #{nonexist_list.size} files"

         nonexist_list.each do |file|
            filepath = rpm = nil

            begin
               ApplicationRecord.transaction do
                  filepath = File.join(branch_path.path, file)
                  Rails.logger.info "IMPORT: file #{filepath}"
                  rpm = Rpm::Base.new(filepath)

                  package = Package.import(branch_path, rpm)

                  affected[:branches] |= [ branch_path.branch.id ]
                  affected[:groups] |= [ package.group.id ]
               end
            rescue SourceIsntFound => e
               error "IMPORT: file '#{ filepath }' #{e.message} source isn't found for #{branch_path.branch.name}"
            rescue InvalidMd5SumError => e
               error "IMPORT: file '#{ filepath }' has invalid MD5 sum"
            rescue => e
               time = time < rpm.buildtime && time || rpm.buildtime
               error "IMPORT: file '#{ filepath }' failed to update, reason: #{e.message} at #{e.backtrace.join("\n\t")}"
            end
         end

         branch_path.update(imported_at: time, srpms_count: branch_path.rpms.count)
      end

      if source.downcase == 'src'
         branch.update(srpms_count: branch.public_srpm_filenames.count)
      end

      UpdateBranchGroups.new(branch_ids: affected[:branches],
                             group_ids: affected[:groups]).do
   end
end
