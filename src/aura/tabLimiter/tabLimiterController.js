({
onTabCreated: function(cmp) {
        var workspace = cmp.find("workspace");
        var limit = cmp.get("v.limit");
        workspace.getAllTabInfo().then(function (tabInfo) {
            if (tabInfo.length > limit) {
                workspace.closeTab({
                    tabId: tabInfo[0].tabId
                });
            }
        });
    }
})