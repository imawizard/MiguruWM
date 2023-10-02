class CircularList {
    __New() {
        this._first := ""
        this._count := 0
    }

    First => this._first
    Last  => this._first ? this._first.previous : ""
    Count => this._count
    Empty => this._count == 0

    Swap(a, b) {
        this._swapTiles(a, b)
    }

    _swapTiles(a, b) {
        if b.next == a {
            if a.next !== b {
                this._swapTiles(b, a)
                return
            } else if a == b {
                return
            }
        } else if a.next == b {
            a.previous.next := b
            b.next.previous := a

            a.next := b.next
            b.next := a

            b.previous := a.previous
            a.previous := b
        } else {
            a.previous.next := b
            b.previous.next := a

            a.next.previous := b
            b.next.previous := a

            tmp := a.next
            a.next := b.next
            b.next := tmp

            tmp := a.previous
            a.previous := b.previous
            b.previous := tmp
        }

        if this._first == a {
            this._first := b
        } else if this._first == b {
            this._first := a
        }
    }

    Append(data, sibling := this.Last) {
        node := { data: data }
        if this._first {
            this._prependTile(node, sibling.next)
        } else {
            node.previous := node
            node.next := node
            this._first := node
        }
        this._count++
        return node
    }

    Prepend(data, sibling := this._first) {
        node := { data: data }
        if this._first {
            this._prependTile(node, sibling)
            if sibling == this._first {
                this._first := node
            }
        } else {
            node.previous := node
            node.next := node
            this._first := node
        }
        this._count++
        return node
    }

    _prependTile(a, b) {
        a.next := b
        a.previous := b.previous
        b.previous.next := a
        b.previous := a
    }

    Drop(node) {
        if node == this._first {
            if node.next !== node {
                this._first := node.next
                this._unlinkTile(node)
            } else {
                this._first := ""
            }
        } else {
            this._unlinkTile(node)
        }
        return --this._count
    }

    _unlinkTile(node) {
        node.previous.next := node.next
        node.next.previous := node.previous
    }
}
