// spectre-kde — system tray curation (Plasma 6 scripting API)
//
// Curates which status items are pinned in the top-bar system tray, in order.
// Only pin items that are reliably available on this hardware; leave the rest
// in knownItems so Plasma surfaces them (in overflow or on the bar) when their
// backing service/device is present. Pinning an item whose service is absent
// makes the whole tray report "unavailable" in Plasma 6.7.

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
        "org.kde.plasma.brightness," +
        "org.kde.plasma.battery," +
        "org.kde.plasma.notifications");
    log.push("systemtray curated");
}

print(log.join("|"));