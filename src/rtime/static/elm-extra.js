/**
 * Created by amitu on 29/09/16.
 */

var app = Elm.Main.fullscreen({
    csrf: document.body.dataset.csrf,
})

app.ports.title.subscribe(function(title) {
    document.title = title + " • rtime";
})

app.ports.get_graph.subscribe(function(val) {
    console.log("ports.get_graph", val)
    app.ports.graphData.send(["", "asd", [[1, 2], [3, 4]]])
})
