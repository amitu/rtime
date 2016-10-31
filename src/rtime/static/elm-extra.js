/**
 * Created by amitu on 29/09/16.
 */

var app = Elm.Main.fullscreen({
    csrf: document.body.dataset.csrf,
})


app.ports.reload.subscribe(function(){
    document.location.reload()
})


app.ports.title.subscribe(function(title) {
    document.title = title + " • rtime"
})


app.ports.get_key.subscribe(function(key){
    console.log("ports.get_key", key)
    setTimeout(function(){
        if (localStorage.hasOwnProperty(key)) {
            app.ports.keyData.send([
                key, [true, localStorage.getItem(key)]
            ])
        } else {
            app.ports.keyData.send([key, [false, ""]])
        }
    }, 0)
})

app.ports.get_keys.subscribe(function(keys){
    console.log("ports.get_keys", keys)
    setTimeout(function(){
        var kd = [];
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i];

            if (localStorage.hasOwnProperty(key)) {
                kd.push([
                    key, [true, localStorage.getItem(key)]
                ])
            } else {
                kd.push([key, [false, ""]])
            }
        }

        app.ports.keysData.send(kd)
    }, 0)
})

app.ports.set_key.subscribe(function(val){
    console.log("ports.set_key", val)
    localStorage.setItem(val[0], val[1])
})


app.ports.clear_key.subscribe(function(key){
    console.log("ports.clear_key", key)
    localStorage.removeItem(key)
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
            app.ports.graphData.send(["server error", ["", val[0], val[1]], [0, 0], []])
            return
        }
        var buffer = oReq.response; // Note: not oReq.responseText
        if (!buffer) {
            app.ports.graphData.send(["no response", ["", val[0], val[1]], [0, 0], []])
            return
        }

        var array = new Uint16Array(buffer)
        var id = ""
        var list = []
        var ceiling = 0

        for (var i = 0; i < array.length && i < 32; i++) {
            id += String.fromCharCode(array[i])
        }

        for (var i = 32; i < array.length && i < 40; i++) {
            ceiling += array[i] * Math.pow(256 * 256, i - 32)
        }

        for (var i = 40; i < array.length && i < 1064; i++) {
            var n = array[i]
            if (n % 1024)
                list.push([n % 1024,  Math.floor(n / 1024)])
        }

        app.ports.graphData.send(["", [id, val[0], val[1]], [val[5], ceiling], list])
    }
    oReq.send(null)

})
