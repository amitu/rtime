var _user$project$Native_Moment = function() {
    function parse(val) {
        var d = moment(val)
        if (d.isValid()) {
            return _elm_lang$core$Result$Ok(d.toDate().getTime())
        } else {
            return _elm_lang$core$Result$Err("invalid date")
        }
    }

    return {
        parse: parse
    }
}()
