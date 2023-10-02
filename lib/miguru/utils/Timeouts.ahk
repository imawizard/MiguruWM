class Timeouts {
    __New() {
        this.timers := Map()
    }

    Add(func, delay, tag := "") {
        if !func {
            return
        }

        entry := { func: func, tag: tag }
        timer := this._callback.Bind(this, entry)
        entry.timer := timer

        this.timers[entry] := entry
        SetTimer(timer, -delay)
    }

    _callback(entry) {
        this.timers.Delete(entry)
        entry.func.Call()
    }

    Replace(func, delay, tag := "") {
        dropped := this.Drop(tag)
        this.Add(func, delay, tag)
        return dropped
    }

    Drop(tag := "") {
        dropped := []
        for k, v in this.timers {
            if !tag || v.tag == tag {
                timer := v.timer
                SetTimer(timer, 0)
                dropped.Push(k)
            }
        }
        for k, v in dropped {
            this.timers.Delete(v)
        }
        return dropped.Length
    }

    Tags() {
        unique := {}
        for k, v in this.timers {
            unique[v.tag] := ""
        }
        tags := []
        for k, v in unique {
            tags.Push(k)
        }
        return tags
    }
}
