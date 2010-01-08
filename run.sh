#!/bin/sh

rake db:drop
rake db:create
rake db:schema:load
rake db:seed
rake sisyphus:groups
rake sisyphus:packagers
rake sisyphus:acls
rake sisyphus:bugs
rake sisyphus:gitrepos
rake sisyphus:repocops
rake sisyphus:leaders
rake sisyphus:teams
#rake sisyphus:ftbfs_i586 ???
rake sisyphus:srpms
rake sisyphus:i586
rake sisyphus:noarch
rake sisyphus:x86_64

rake 51:groups
rake 51:acls
rake 51:leaders
rake 51:teams
rake 51:srpms
rake 51:i586
rake 51:noarch
rake 51:x86_64

rake platform5:groups
rake platform5:acls
rake platform5:leaders
rake platform5:teams
rake platform5:srpms
rake platform5:i586
rake platform5:noarch
rake platform5:x86_64

rake 50:groups
rake 50:acls
rake 50:leaders
rake 50:teams
rake 50:srpms
rake 50:i586
rake 50:noarch
rake 50:x86_64

rake 41:groups
rale 41:acls
rake 41:leaders
rake 41:teams
rake 41:srpms
rake 41:i586
rake 41:noarch
rake 41:x86_64

rake 40:groups
rake 40:acls
rake 40:leaders
rake 40:teams
rake 40:srpms
rake 40:i586
rake 40:noarch
rake 40:x86_64

