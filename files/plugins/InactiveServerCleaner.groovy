import org.artifactory.api.context.ContextHelper
import org.artifactory.storage.db.servers.service.ArtifactoryServersCommonService
import org.slf4j.Logger

jobs {
    clean(cron: "1/30 * * * * ?") {
        def artifactoryServersCommonService = ContextHelper.get().beanForType(ArtifactoryServersCommonService)
        new ArtifactoryInactiveServersCleaner(artifactoryServersCommonService, log).cleanInactiveArtifactoryServers()
    }
}

public class ArtifactoryInactiveServersCleaner {

    private ArtifactoryServersCommonService artifactoryServersCommonService
    private Logger log

    ArtifactoryInactiveServersCleaner(ArtifactoryServersCommonService artifactoryServersCommonService, Logger log) {
        this.artifactoryServersCommonService = artifactoryServersCommonService
        this.log = log
    }

    List<String> cleanInactiveArtifactoryServers() {
        String primaryId = artifactoryServersCommonService.getRunningHaPrimary()?.serverId
        if (primaryId) {
            List<String> allMembers = artifactoryServersCommonService.getAllArtifactoryServers().collect({ it.serverId })
            List<String> activeMembersIds = artifactoryServersCommonService.getOtherActiveMembers().collect({ it.serverId })
            List<String> inactiveMembers = allMembers - activeMembersIds - primaryId
            log.info "Running inactive artifactory servers cleaning task, found ${inactiveMembers.size()} inactive servers to remove"
            for (String inactiveMember : inactiveMembers) {
                artifactoryServersCommonService.removeServer(inactiveMember)
            }
            return inactiveMembers
        }
    }

}