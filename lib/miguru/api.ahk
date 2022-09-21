class MiguruAPI {
    FocusWorkspace(target) {
        if (this.VD.CurrentDesktop() != target) {
            this.VD.FocusDesktop(target)
        }
    }

    SendToWorkspace(target) {
        this.VD.SendWindowToDesktop(WinExist("A"), target)
    }
}
