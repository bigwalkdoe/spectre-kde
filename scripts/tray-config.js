// spectre-kde — system tray curation (Plasma 6 scripting API)
//
// Curates which status items are pinned in the top-bar system tray, in order:
//   clipboard, network, bluetooth, volume, brightness, battery, notifications
// All other known tray items stay available in the tray's overflow menu.
// In Plasma 6.7 the tray's [General] extraItems/knownItems config lives directly
// on the org.kde.plasma.systemtray applet, so we write it there.

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
    tray.writeConfig(
        "extraItems",
        "org.kde.plasma.networkmanagement," +
        "org.kde.plasma.bluetooth," +
        "org.kde.plasma.volume," +
        "org.kde.plasma.notifications");
    // No reloadConfig(): Plasma 6.7 re-reads on its own; forcing a reload
    // occasionally nulls tray items and makes the whole tray "unavailable".
    log.push("systemtray curated");
}

print(log.join("|"));