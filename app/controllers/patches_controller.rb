# frozen_string_literal: true

class PatchesController < ApplicationController
   before_action :set_evrb, except: :download
   before_action :fetch_spkg, except: %i(show download)
   before_action :fetch_spkgs_by_name, only: %i(index)
   before_action :fetch_patch, only: %i(show download)
   before_action :fetch_bugs, only: :index

   def index
      @patches = Patch.for_packages(@spkgs).presented.uniq_by(:patch)
   end

   def show
      @html_data = Rouge::Formatters::HTMLLegacy.new(css_class: 'highlight', line_numbers: true).format(Rouge::Lexers::Diff.new.lex(@patch.patch)).force_encoding("UTF-8")
   end

   def download
      send_data(@patch.patch, disposition: 'attachment', filename: @patch.filename)
   end

   protected

   def fetch_spkg
      includes = {
          index: %i(patches),
      }[action_name.to_sym]

      spkgs = @branch.spkgs.by_name(params[:reponame]).by_evr(params[:evrb]).order(buildtime: :desc)
      @spkgs = spkgs.includes(*includes) if includes
      
      @spkg = @spkgs.first!
   end

   def fetch_spkgs_by_name
      @spkgs_by_name = SrpmBranchesSerializer.new(Rpm.src
                                                     .by_name(params[:reponame])
                                                     .joins(:branch)
                                                     .merge(Branch.published)
                                                     .includes(:branch_path, :branch, :package)
                                                     .order('packages.buildtime DESC, branches.order_id'))
   end

   def set_evrb
      @evrb = params[:evrb]
   end

   def package_attrs
      attrs = {
         name: params[:reponame],
         arch: "src"
      }

      if /(?:(?<epoch>\d+):)?(?<version>[^-]+)-(?<release>[^-]+)-(?<built_at>\d+)$/ =~ params[:evrb]
         attrs.merge!(epoch: epoch,
                      version: version,
                      release: release,
                      buildtime: Time.at(built_at.to_i))
      end

      attrs
   end

   def fetch_bugs
      @all_bugs = AllBugsForSrpm.new(spkg: @spkg, branch: @branch).decorate
      @opened_bugs = OpenedBugsForSrpm.new(spkg: @spkg, branch: @branch).decorate
   end

   def fetch_patch
      attrs = { filename: params[:patch_name], packages: package_attrs }
      patches = Patch.joins(:package).where(attrs)
      @patch = patches.find { |patch| patch.patch? } || raise(ActiveRecord::RecordNotFound)
   end
end
