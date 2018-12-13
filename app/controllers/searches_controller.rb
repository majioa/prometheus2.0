# frozen_string_literal: true

class SearchesController < ApplicationController
   before_action :fix_arches
   before_action :set_branch

   def show
      @branches = Branch.all
      if params[:query].blank? and params[:arch].blank?
         redirect_to controller: 'home', action: 'index'
      else
         @spkgs = Package::Src.b(@branch.slug)
                              .a(@arches)
                              .q(params[:query])
                              .order(order_sql)
                              .unscope(:select)
                              .select(select_sql)
                              .page(params[:page])

         if @spkgs.total_count == 1 && @spkgs.first.branches.first
           redirect_to(srpm_path(@spkgs.first.branches.first, @spkgs.first), status: 302)
         end
      end
   end

   protected

   # fixes noarch arch call when blank TODO
   def fix_arches
      arches = [ params[:arch] ].flatten.compact.select { |a| a.present? }
      @arches = arches.any? { |a| a != 'noarch' } && arches || nil
   end

   def set_branch
      @branch = Branch.find_or_initialize_by(slug: params[:branch]).decorate
   end

   def select_sql
      if params[:query].blank?
         "DISTINCT on(packages.name) packages.*"
      else
         "DISTINCT on(qs.rank, packages.name) packages.*, branches.slug, qs.rank, qs.evrbes, qs.slugs"
      end
   end

   def order_sql
      if params[:query].blank?
         "packages.name, branches.order_id DESC"
      else
         "qs.rank DESC, packages.name, branches.order_id DESC"
      end
   end
end
