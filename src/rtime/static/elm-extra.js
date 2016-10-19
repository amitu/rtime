/**
 * Created by amitu on 29/09/16.
 */

var app = Elm.Main.fullscreen({
    csrf: document.body.dataset.csrf,
})

app.ports.title.subscribe(function(title) {
    document.title = title + " • rtime";
})
