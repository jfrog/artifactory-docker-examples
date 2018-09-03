//JFrog Xray MongoDB Bootstrap

//Creating default admin user
var adminUser = {
    user:"admin",
    pwd: "password",
    roles: ["root"],
    customData: {
        createdBy: "JFrog Xray installer"
    }
}
db.getSiblingDB("admin").createUser(adminUser)

//Creating default xray user
var xrayUser = {
    user:"xray",
    pwd: "password",
    roles: ["dbOwner"],
    customData: {
        createdBy: "JFrog Xray installer"
    }
}

//Authenticating as admin to create xray user
var loginOutput = db.getSiblingDB("admin").auth(adminUser.user,adminUser.pwd)
db.getSiblingDB("xray").createUser(xrayUser)