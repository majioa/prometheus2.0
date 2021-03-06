# frozen_string_literal: true

Rails.application.routes.draw do

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

   authenticate :user, ->(user) { user.admin? } do
      mount PgHero::Engine, at: 'pghero'
   end

   # support old rules
   # from v2:packages.a.o
   get 'uk', to: redirect('/ru')
   get 'br', to: redirect('/en')
   get '*prefix/Platform6/*other', to: redirect { |pp, _| "/#{pp[:prefix]}/p6/#{pp[:other]}" }
   get '*prefix/Platform5/*other', to: redirect { |pp, _| "/#{pp[:prefix]}/p5/#{pp[:other]}" }
   get 'uk/*other', to: redirect { |pp, _| "/ru/#{pp[:other]}" }
   get 'br/*other', to: redirect { |pp, _| "/en/#{pp[:other]}" }
   get 'project', to: redirect('/ru/project')

   devise_for :users

   scope '(:locale)', locale: SUPPORTED_LOCALES_RE do
      root to: 'srpms#index'

      # support old rules
      # from v2:packages.a.o
      get ':branch/srpms/:reponame/changelog', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/changelogs')
      get ':branch/srpms/:reponame/spec', to: redirect('/%{locale}/%{branch}/specfiles/%{reponame}')
      get ':branch/srpms/:reponame/rawspec', to: redirect('/%{locale}/%{branch}/specfiles/%{reponame}/raw')
      get ':branch/srpms/:reponame/get', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/rpms')
      get ':branch/srpms/:reponame/gear', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}')
      get ':branch/srpms/:reponame/bugs', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/issues#bug')
      get ':branch/srpms/:reponame/allbugs', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/issues#bug?q=all')
      get ':branch/srpms/:reponame/repocop', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/repocop_notes')
      get ':branch/maintainers/:login/gear', to: redirect('/%{locale}/%{branch}/maintainers/%{login}/gears')
      get ':branch/maintainers/:login/ftbfs', to: redirect('/%{locale}/%{branch}/maintainers/%{login}/ftbfses')
      get ':branch/maintainers/:login/allbugs', to: redirect('/%{locale}/%{branch}/maintainers/%{login}/bugs?q=all')
      get ':branch/maintainers/:login/repocop', to: redirect('/%{locale}/%{branch}/maintainers/%{login}/repocop_notes')

      # from v1:sisyphus.ru
      get 'srpm/:branch/:reponame', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}')
      get 'srpm/:branch/:reponame/changelog', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/changelogs')
      get 'srpm/:branch/:reponame/spec', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/spec')
      get 'srpm/:branch/:reponame/patches', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/patches')
      get 'srpm/:branch/:reponame/patches/:id', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/patches/%{id}')
      get 'srpm/:branch/:reponame/sources', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/sources')
      get 'srpm/:branch/:reponame/sources/:id', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/sources/%{id}')
      get 'srpm/:branch/:reponame/getsource/:id', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/sources/%{id}/download')
      get 'srpm/:branch/:reponame/get', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/rpms')
      get 'srpm/:branch/:reponame/gear', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}')
      get 'srpm/:branch/:reponame/allbugs', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/issues#bug?q=all')
      get 'srpm/:branch/:reponame/bugs', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/issues#bug')
      get 'srpm/:branch/:reponame/repocop', to: redirect('/%{locale}/%{branch}/srpms/%{reponame}/repocop_notes')
      get 'people', to: redirect('/%{locale}/sisyphus/maintainers')
      get 'packager/:login', to: redirect('/%{locale}/sisyphus/maintainers/%{login}')
      get 'packager/:login/srpms', to: redirect('/%{locale}/sisyphus/maintainers/%{login}/srpms')
      get 'packager/:login/bugs', to: redirect('/%{locale}/sisyphus/maintainers/%{login}/issues#bug')
      get 'packager/:login/repocop', to: redirect('/%{locale}/sisyphus/maintainers/%{login}/repocop_notes')
      get 'team/:login', to: redirect('/%{locale}/sisyphus/teams/%{login}')
      get 'security', to: redirect('/%{locale}/sisyphus/security'), as: :v1_security
      get 'packages', to: redirect('/%{locale}/sisyphus/packages'), as: :v1_packages
      get 'packages/:group1', to: redirect { |pp, _| "/#{pp[:locale]}/sisyphus/packages/#{pp[:group1].downcase}" }
      get 'packages/:group1/:group2', to: redirect { |pp, _| "/#{pp[:locale]}/sisyphus/packages/#{pp[:group1].downcase}_#{pp[:group2].downcase}" }
      get 'packages/:group1/:group2/:group3', to: redirect { |pp, _| "/#{pp[:locale]}/sisyphus/packages/#{pp[:group1].downcase}_#{pp[:group2].downcase}_#{pp[:group3].downcase}" }

      get 'project' => 'pages#project'

      scope '(:branch)', branch: /([^\/]+)/ do
         get 'home' => 'srpms#index', as: 'home'

         resources :specfiles, param: :reponame, reponame: /[^\/]+/, only: :show do
            get :raw, on: :member
         end

         resources :srpms, param: :reponame, reponame: /[^\/]+/, only: %i(show) do
            member do
               resources :changelogs, only: :index
               resources :patches, param: :patch_name, patch_name: /[^\/]+/, only: %i(index show) do
                  get :download, on: :member
               end
               resources :sources, param: :source_name, source_name: /[^\/]+/, only: %i(index show) do
                  get :download, on: :member
               end
               resources :rpms, param: :rpm_name, rpm_name: /[^\/]+/, only: :index
               resources :issues, param: :no, no: /[^\/]+/, only: :index
               resources :repocop_notes, param: :no, no: /[^\/]+/, only: :index
               resources :gears, only: [] do
                  get :repos, on: :collection
               end
               resources :tasks, only: [] do
                  get :pkg_index, on: :collection
               end
            end
         end

         scope :specfiles do
            scope '(:reponame)', reponame: /[^\/]+/ do
               scope '(:evrb)', evrb: /[^\/]+/ do
                  get '/' => 'specfiles#show', as: 'evrb_specfile'
                  get 'raw' => 'specfiles#raw', as: 'raw_evrb_specfile'
               end
            end
         end

         scope :srpms do
            scope '(:reponame)', reponame: /[^\/]+/ do
               scope '(:evrb)', evrb: /[^\/]+/ do
                  get '/' => 'srpms#show', as: 'evrb_srpm'
                  resources :changelogs, only: :index, as: :evrb_changelogs
                  resources :patches, param: :patch_name, only: %i(index show), as: :evrb_patches do
                     get :download, on: :member
                  end
                  resources :sources, param: :source_name, only: %i(index show), as: :evrb_sources do
                     get :download, on: :member
                  end
                  resources :rpms, param: :rpm_name, rpm_name: /[^\/]+/, only: :index, as: :evrb_rpms
                  resources :issues, param: :no, only: :index, as: :evrb_issues
                  resources :repocop_notes, param: :no, only: :index, as: :evrb_repocop_notes
                  resources :gears, as: :evrb_gears do
                     get :repos, on: :collection
                  end
                  resources :tasks, as: :evrb_tasks do
                     get :pkg_index, on: :collection
                  end
               end
            end
         end

         get 'rss' => 'rss#index', as: 'rss'
         resources :teams, param: :login, only: %i(index show)

         resources :maintainers, param: 'login', only: %i(index show) do
            member do
               resources :srpms, param: :reponame, reponame: /[^\/]+/, only: [], as: :maintainer_srpms do
                  get '/' => 'srpms#maintained', on: :collection
               end
               resources :gears, param: :reponame, reponame: /[^\/]+/, only: :index
               get 'bugs' => 'issues#bugs'
               get 'ftbfses' => 'issues#ftbfses'
               get 'watch' => 'issues#novelties', as: 'novelties'
               resources :repocop_notes, param: :no, only: [], as: :maintainer_repocop_notes do
                  get '/' => 'repocop_notes#maintained', on: :collection
               end
               resources :tasks, param: :reponame, reponame: /[^\/]+/, only: :index
            end
         end

         get 'packages/:slug' => 'group#show', slug: /[a-z0-9_]+/, as: 'group'
         get 'packages' => 'group#index', as: 'packages'

         get 'security' => 'security#index', as: 'security'

         # support old rules
         # from v2:packages.a.o
         get 'packages/:group1', to: redirect { |pp, _| "/#{pp[:locale]}/#{pp[:branch]}/packages/#{pp[:group1].downcase}" }
         get 'packages/:group1/:group2', to: redirect { |pp, _| "/#{pp[:locale]}/#{pp[:branch]}/packages/#{pp[:group1].downcase}_#{pp[:group2].downcase}" }
         get 'packages/:group1/:group2/:group3', to: redirect { |pp, _| "/#{pp[:locale]}/#{pp[:branch]}/packages/#{pp[:group1].downcase}_#{pp[:group2].downcase}_#{pp[:group3].downcase}" }
      end

      resource :search, only: :show

      resources :rsync, controller: :rsync, only: %i(new) do
         post :generate, on: :collection
      end
   end

   resources :repocop_patches, param: :package_id, only: [] do
      get :download, on: :member
   end

   get '/:reponame', reponame: /[^:\/]+/, to: "srpms#find_first"
   get '/src::reponame', reponame: /[^\/]+/, to: redirect('/%{reponame}')

   resources :tags
end
