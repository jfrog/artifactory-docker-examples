import groovy.transform.Field
import org.artifactory.api.context.ContextHelper
import org.artifactory.api.security.SecurityService
import org.artifactory.api.security.UserGroupService
import org.artifactory.factory.InfoFactoryHolder
import org.artifactory.security.UserInfo
import org.artifactory.security.props.auth.ApiKeyManager
import org.artifactory.security.props.auth.model.TokenKeyValue
import org.artifactory.storage.db.servers.service.ArtifactoryServersCommonService
import org.slf4j.Logger

@Field
final String internalUserName = '_internal'
createInternalUserIfNeeded()

jobs {
    clean(cron: "1/30 * * * * ?") {
        def artifactoryServersCommonService = ContextHelper.get().beanForType(ArtifactoryServersCommonService)
        new ArtifactoryInactiveServersCleaner(artifactoryServersCommonService, log).cleanInactiveArtifactoryServers()
    }
}

void createInternalUserIfNeeded() {
    String password='b6a50c8a15ece8753e37cbe5700bf84f'
    UserGroupService userGroupService = ContextHelper.get().beanForType(UserGroupService)
    SecurityService securityService = ContextHelper.get().beanForType(SecurityService)
    ApiKeyManager apiKeyManager = ContextHelper.get().beanForType(ApiKeyManager)
    UserInfo user = userGroupService.findOrCreateExternalAuthUser(internalUserName, false)
    def saltedPassword = securityService.generateSaltedPassword(password)
    def newUser = InfoFactoryHolder.get().copyUser(user)
    // We should decide if we use a fixed password on the first start for convenience
    // or if we fail fast on other services if no API_KEY is provided
    newUser.setPassword(saltedPassword)
    newUser.setAdmin(false)
    newUser.setInternalGroups(Collections.emptySet())
    newUser.setGroups(Collections.emptySet())
    userGroupService.updateUser(newUser, false)
    TokenKeyValue token = apiKeyManager.getToken(internalUserName)
    if (!token) {
        token = apiKeyManager.createToken(internalUserName);
        log.warn "API Key generated for user $internalUserName : $token.token \n" +
                "You should use this API key for communicating with the primary and disable internal password"
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