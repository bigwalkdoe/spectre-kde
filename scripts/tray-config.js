// spectre-kde — system tray curation (Plasma 6 scripting API)
//
// Curates which status items are pinned in the top-bar system tray, in order.
//
// Two keys are written for the same list:
//   extraItems  - pins the items (drives applet creation; a *change* here is
//                 what makes plasmashell (re)create the pinned applets)
//   shownItems  - forces the items into the always-visible row. Without it,
//                 freshly created applets can report PassiveStatus and land in
//                 the expander popup (or, with HiddenStatus, not show at all).
//                 "Pinned" should mean visible, so both keys carry the list.

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

var ITEMS =
    "org.kde.plasma.clipboard," +
    "org.kde.plasma.networkmanagement," +
    "org.kde.plasma.bluetooth," +
    "org.kde.plasma.volume," +
    "org.kde.plasma.brightness," +
    "org.kde.plasma.battery," +
    "org.kde.plasma.notifications";

if (!tray) {
    log.push("ERROR systemtray not found in any panel");
} else {
    tray.currentConfigGroup = ["General"];
    try {
        tray.writeConfig("extraItems", ITEMS);
        tray.writeConfig("shownItems", ITEMS);
        log.push("systemtray curated");
    } catch (e) {
        log.push("WARN tray curation failed (non-fatal): " + e);
    }
}

print(log.join("|"));
