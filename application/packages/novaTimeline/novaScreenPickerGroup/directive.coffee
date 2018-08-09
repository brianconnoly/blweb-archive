*deps: groupService
*replace: true

scope.groups = groupService.getByProjectId scope.postParams.projectId
