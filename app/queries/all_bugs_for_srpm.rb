# frozen_string_literal: true

class AllBugsForSrpm < Rectify::Query
  attr_reader :spkg, :branch

  def initialize(spkg: nil, branch: nil)
    @spkg = spkg
    @branch = branch
  end

  def query
    Issue::Bug.where(repo_name: reponames,
                     branch_path_id: branch.branch_paths.select(:id))
              .order(no: :desc)
  end

  def decorate
    BugDecorator.decorate_collection(query)
  end

  protected

  def reponames
    @reponames ||= spkg.packages.select(:name).distinct
  end
end
