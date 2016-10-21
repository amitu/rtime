/**
 * Created by amitu on 29/09/16.
 */

var app = Elm.Main.fullscreen({
    csrf: document.body.dataset.csrf,
})


app.ports.title.subscribe(function(title) {
    document.title = title + " • rtime"
})


app.ports.get_graph.subscribe(function(val) {
    console.log("ports.get_graph", val)

    var oReq = new XMLHttpRequest()
    oReq.open(
        "GET", (
            // app view host start end floor ceiling
            "/view?app=" + encodeURIComponent(val[0])
            + "&view=" + encodeURIComponent(val[1])
            + "&host=" + encodeURIComponent(val[2])
            + "&start=" + encodeURIComponent(val[3])
            + "&end=" + encodeURIComponent(val[4])
            + "&floor=" + encodeURIComponent(val[5])
            + "&ceiling=" + encodeURIComponent(val[6])
        ),
        true
    )
    oReq.responseType = "arraybuffer"

    oReq.onload = function (oEvent) {
        if (oReq.status != 200) {
            app.ports.graphData.send(["server error", "", 0, []])
            return
        }
        var buffer = oReq.response; // Note: not oReq.responseText
        if (!buffer) {
            app.ports.graphData.send(["no response", "", 0, []])
            return
        }

        var array = new Uint16Array(buffer)
        var id = ""
        var list = []
        var ceiling = 0;

        for (var i = 0; i < array.length && i < 32; i++) {
            id += String.fromCharCode(array[i])
        }

        for (var i = 32; i < array.length && i < 40; i++) {
            ceiling += array[i] * Math.pow(256 * 256, i - 32)
        }

        for (var i = 40; i < array.length; i++) {
            var n = array[i]
            list.push([n % 1024,  Math.ceil(n / 1024)])
        }

        app.ports.graphData.send(["", id, ceiling, list])
    }
    oReq.send(null)

})
