# frozen_string_literal: true

class BranchingMaintainer < ApplicationRecord
   belongs_to :branch
   belongs_to :maintainer

   delegate :name, :slug, :login, to: :maintainer
   delegate :name, :slug, to: :branch, prefix: true

   scope :useful, -> { where.not(srpms_count: 0) }
   scope :for_branch, ->(branch) { where(branch_id: branch) }
   scope :person, -> { joins(:maintainer).merge(Maintainer.person) }
   scope :team, -> { joins(:maintainer).merge(Maintainer.team) }
   scope :top, ->(limit, branch) do
      person.where(branch_id: branch.id)
            .where.not(srpms_count: 0)
            .order('branching_maintainers.srpms_count DESC')
            .limit(limit)
   end

   def update_count!
      srpms_count = maintainer.packages
                              .joins(:branch_paths)
                              .where(branch_paths: { branch_id: branch })
                              .merge(BranchPath.published)
                              .select("DISTINCT ON(packages.name) packages.*")
                              .size

      self.update!(srpms_count: srpms_count)
   end
end
