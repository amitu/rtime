/**
 * Created by amitu on 29/09/16.
 */

var app = Elm.Main.fullscreen({
    csrf: document.body.dataset.csrf,
    store: get_local_store(),
})

function get_local_store() {
    var data = []
    for (var i = 0; i < localStorage.length; i++){
        data.push(
            [localStorage.key(i), localStorage.getItem(localStorage.key(i))]
        )
    }
    return data
}

app.ports.reload.subscribe(function(){
    document.location.reload()
})


app.ports.title.subscribe(function(title) {
    document.title = title + " • rtime"
})

app.ports.get_key.subscribe(function(key){
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
    localStorage.setItem(val[0], val[1])
})

app.ports.set_keys.subscribe(function(vals){
    for (var i = 0; i < vals.length; i++) {
        var val = vals[i];
        localStorage.setItem(val[0], val[1])
    }
})

app.ports.clear_key.subscribe(function(key){
    localStorage.removeItem(key)
})


function join(name, vals, sep) {
    res = ""
    for (var i = 0; i < vals.length; i++) {
        res += name + "=" + encodeURIComponent(vals[i].join(sep)) + "&"
    }
    return res
}

function error(specs, err) {
    // spec, err, id, (floor, ceiling), List Point
    var result = []
    for (var s = 0; s < specs.length; s++) {
        var spec = specs[s][0] + ":" + specs[s][1] + ":"
        result.push([spec, err, "", [0, 0], []])
    }
    app.ports.graphsData.send(result)
}

app.ports.get_graphs.subscribe(function(val) {
    var oReq = new XMLHttpRequest()
    oReq.open(
        "GET", (
            // [spec] start end floor ceiling
            "/graph?" + join("specs", val[0], ":")
            + "&start=" + encodeURIComponent(val[1])
            + "&end=" + encodeURIComponent(val[2])
            + "&floor=" + encodeURIComponent(val[3])
            + "&ceiling=" + encodeURIComponent(val[4])
        ),
        true
    )
    oReq.responseType = "arraybuffer"

    oReq.onerror = function(e) {
        return error(val[0], "server error")
    }

    oReq.onload = function (oEvent) {
        if (oReq.readyState == 0) {
            return error(val[0], "network error")
        }
        if (oReq.status != 200) {
            return error(val[0], "server error")
        }
        var buffer = oReq.response; // Note: not oReq.responseText
        if (!buffer) {
            return error(val[0], "no response")
        }

        var array = new Uint16Array(buffer)
        var result = []

        for (var s = 0; s < val[0].length; s++) {
            var offset = s * 1060 // bytes per graph
            var id = ""
            var list = []
            var ceiling = 0
            var spec = val[0][s][0] + ":" + val[0][s][1] + ":"

            for (var i = offset; i < array.length && i < offset + 32; i++) {
                id += String.fromCharCode(array[i])
            }

            for (var i = offset + 32; i < array.length && i < offset + 36; i++) {
                ceiling += array[i] * Math.pow(256 * 256, i - offset - 32)
            }

            for (var i = offset + 36; i < array.length && i < offset + 1060; i++) {
                var n = array[i]
                if (n % 1024)
                    list.push([n % 1024,  Math.floor(n / 1024)])
            }

            // spec, err, id, (floor, ceiling), List Point
            result.push([spec, "", id, [val[3], ceiling], list])
        }
        app.ports.graphsData.send(result)
    }
    oReq.send(null)

})
