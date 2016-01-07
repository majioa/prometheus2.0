module Api
  module Docs
    class Packages
      # :nocov:
      include Swagger::Blocks

      swagger_schema :Package do
        key :required, [:id, :srpm_id, :name, :version, :release, :epoch,
                        :arch, :summary, :license, :url, :description,
                        :buildtime, :group_id, :md5, :groupname, :size,
                        :filename, :sourcepackage, :created_at, :updated_at]
        property :id do
          key :type, :integer
          key :format, :int64
          key :description, 'Package ID.'
        end
        property :srpm_id do
          key :type, :integer
          key :format, :int64
          key :description, 'Srpm ID.'
        end
        property :name do
          key :type, :string
          key :description, 'Package name'
        end
        property :version do
          key :type, :string
          key :description, 'Package version'
        end
        property :release do
          key :type, :string
          key :description, 'Package release'
        end
        property :epoch do
          key :type, :integer
          key :format, :int64
          key :description, 'Package epoch'
        end
        property :arch do
          key :type, :string
          key :description, 'Package arch'
        end
        property :summary do
          key :type, :string
          key :description, 'Package summary'
        end
        property :license do
          key :type, :string
          key :description, 'Package license'
        end
        property :url do
          key :type, :string
          key :description, 'Package url'
        end
        property :description do
          key :type, :string
          key :description, 'Package description'
        end
        property :buildtime do
          key :type, :string
          key :format, :'date-time'
          key :description, 'Buildtime in ISO8601 format'
        end
        property :group_id do
          key :type, :integer
          key :format, :int64
          key :description, 'Package group id'
        end
        property :md5 do
          key :type, :string
          key :description, 'Package md5 sum'
        end
        property :groupname do
          key :type, :string
          key :description, 'Package group name'
        end
        property :size do
          key :type, :integer
          key :format, :int64
          key :description, 'Package size'
        end
        property :filename do
          key :type, :string
          key :description, 'Package filename'
        end
        property :sourcepackage do
          key :type, :string
          key :description, 'Package source rpm'
        end
        property :created_at do
          key :type, :string
          key :format, :'date-time'
          key :description, 'Created at in ISO8601 format'
        end
        property :updated_at do
          key :type, :string
          key :format, :'date-time'
          key :description, 'Updated at in ISO8601 format'
        end
      end

      swagger_path '/srpms/{name}/packages' do
        operation :get do
          key :description, 'Returns srpm packages info for given name'
          key :operationId, 'findPackagesForSrpm'
          key :tags, ['packages']
          parameter do
            key :name, :name
            key :in, :path
            key :description, 'Srpm name'
            key :required, true
            key :type, :string
          end
          parameter do
            key :name, :branch_id
            key :in, :query
            key :description, 'Branch id. Default: Sisyphus branch id, not name. E.g. 1.'
            key :type, :integer
            key :format, :int64
          end
          response 200 do
            key :description, 'Response with packages.'
            schema do
              key :type, :array
              items do
                key :'$ref', :Package
              end
            end
          end
          response 404 do
            key :description, 'Srpm and/or Branch not found.'
          end
        end
      end

      # :nocov:
    end
  end
end