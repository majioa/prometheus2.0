# frozen_string_literal: true

class SourcesController < ApplicationController
   include Srpmable

   before_action :set_evrb, except: :download
   before_action :fetch_spkg, except: %i(download)
   before_action :fetch_spkgs_by_name, only: %i(index)
   before_action :fetch_source, only: %i(download)
   before_action :fetch_bugs, only: :index

   def index
      @sources = @spkg.sources
   end

   def download
      send_data(@source.content, disposition: 'attachment', filename: @source.filename)
   end

   protected

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

   def fetch_source
      attrs = { filename: params[:source_name], packages: package_attrs }
      sources = Source.joins(:package).where(attrs)
      @source = sources.find { |source| source.content? } || raise(ActiveRecord::RecordNotFound)
   end
end
