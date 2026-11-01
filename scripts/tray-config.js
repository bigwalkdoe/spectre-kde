// spectre-kde — system tray curation (Plasma 6 scripting API)
//
// Curates which status items are pinned in the top-bar system tray, in order.

var log = [];
var tray = null;

var ids = panelIds.slice();
for (var i = 0; i < ids.length; i++) {
    var p = panelById(ids[i]);
    if (!p) continue;
    var wids = p.widgetIds;
    for (var w = 0; w < wids.length; w++) {
        var wid = p.widgetById(wids[w]);
        if (wid && wid.type === "org.kde.plasma.systemtray") {
            tray = wid;
        }
    }
}

if (!tray) {
    log.push("ERROR systemtray not found in any panel");
} else {
    tray.currentConfigGroup = ["General"];
    try {
        tray.writeConfig(
            "extraItems",
            "org.kde.plasma.clipboard," +
            "org.kde.plasma.networkmanagement," +
            "org.kde.plasma.bluetooth," +
            "org.kde.plasma.volume," +
            "org.kde.plasma.brightness," +
            "org.kde.plasma.battery," +
            "org.kde.plasma.notifications"
        );
        log.push("systemtray curated");
    } catch (e) {
        log.push("WARN tray curation failed (non-fatal): " + e);
    }
}

print(log.join("|"));
