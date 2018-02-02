import org.artifactory.state.ArtifactoryServerState
import org.artifactory.storage.db.servers.service.ArtifactoryServersCommonService
import org.artifactory.common.ConstantValues
import org.slf4j.Logger
import java.util.concurrent.TimeUnit

jobs {
    clean(cron: "* 0/1 * * * ?") {
        def artifactoryServersCommonService = ctx.beanForType(ArtifactoryServersCommonService)
        def artifactoryInactiveServerCleaner = new ArtifactoryInactiveServersCleaner(artifactoryServersCommonService, log)
        artifactoryInactiveServerCleaner.cleanInactiveArtifactoryServers()
    }
}

public class ArtifactoryInactiveServersCleaner {

    private ArtifactoryServersCommonService artifactoryServersCommonService
    private Logger log

    ArtifactoryInactiveServersCleaner(ArtifactoryServersCommonService artifactoryServersCommonService, Logger log) {
        this.artifactoryServersCommonService = artifactoryServersCommonService
        this.log = log
    }

    def cleanInactiveArtifactoryServers() {
        List<String> allMembers = artifactoryServersCommonService.getAllArtifactoryServers()
        for (member in allMembers) {
            def heartbeat = TimeUnit.MILLISECONDS.toSeconds(System.currentTimeMillis() - member.getLastHeartbeat())
            def noheartbeat = heartbeat > ConstantValues.haHeartbeatStaleIntervalSecs.getInt()
            if (member.getServerState() == ArtifactoryServerState.UNAVAILABLE || noheartbeat) {
                log.info "Running inactive artifactory servers cleaning task, found ${member.serverId} inactive servers to " +
                        "remove"
                artifactoryServersCommonService.removeServer(member.serverId)
            }
        }
    }
}
