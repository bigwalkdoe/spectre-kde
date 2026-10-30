// spectre-kde — shared panels probe (Plasma 6 scripting API)
//
// Single source of truth for "what panels/widgets exist right now", used by
// both detect.sh (human inventory) and verify.sh (PASS/FAIL checks).
//
// Output (one line per panel, '|'-joined; parse in bash):
//   count=<n>|panelids=<id,...>|panelids|<location>;h=<height>;float=<true|false>;align=<n>;widgets=<type,...>
// Locations are the stable Plasma strings: top|bottom|left|right|desktop.
//
// `align` is the live Qt::Alignment value from the scripting API. Plasma only
// flushes alignment to plasmashellrc on shell exit, so after a quick update
// (no restart) the on-disk key can be missing even though the live shell is
// centered; the live probe is authoritative here.
//
// panelids= is the LIVE panel id set. Callers need it because plasmashellrc on
// disk lags the running shell and can transiently contain [PlasmaViews][Panel N]
// sections for panels that no longer exist; only the live ids describe reality.

var log = [];

var ids = panelIds.slice();
log.push("count=" + ids.length);
log.push("panelids=" + ids.join(","));
for (var i = 0; i < ids.length; i++) {
    var p = panelById(ids[i]);
    if (!p) { continue; }
    var wtypes = [];
    var wids = p.widgetIds;
    for (var w = 0; w < wids.length; w++) {
        var wid = p.widgetById(wids[w]);
        if (wid) { wtypes.push(wid.type); }
    }
    log.push(p.location + ";h=" + Math.round(p.height) + ";float=" + p.floating +
             ";align=" + p.alignment + ";screen=" + p.screen + ";widgets=" + wtypes.join(",") + ";pid=" + p.id);
}

print(log.join("|"));