let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#tabs#SetTabLabel(tabnr, label, auto)
    call settabvar(a:tabnr, "CtrlSpaceLabel", a:label)
    call settabvar(a:tabnr, "CtrlSpaceAutotab", a:auto)
endfunction

function! ctrlspace#tabs#NewTabLabel(tabnr)
    let tabnr = a:tabnr > 0 ? a:tabnr : tabpagenr()
    let label = ctrlspace#ui#GetInput("Label for tab " . tabnr . ": ", gettabvar(tabnr, "CtrlSpaceLabel"))
    if !empty(label)
        call ctrlspace#tabs#SetTabLabel(tabnr, label, 0)
    endif
endfunction

function! ctrlspace#tabs#RemoveTabLabel(tabnr)
    let tabnr = a:tabnr > 0 ? a:tabnr : tabpagenr()
    call ctrlspace#tabs#SetTabLabel(tabnr, "", 0)
endfunction

function! ctrlspace#tabs#CloseTab()
    if tabpagenr("$") == 1
        return
    endif

    if exists("t:CtrlSpaceAutotab") && (t:CtrlSpaceAutotab != 0)
        " do nothing
    elseif exists("t:CtrlSpaceLabel") && !empty(t:CtrlSpaceLabel)
        let bufCount = len(ctrlspace#buffers#Buffers(tabpagenr()))

        if (bufCount > 1) && !ctrlspace#ui#Confirmed("Close tab named '" . t:CtrlSpaceLabel . "' with " . bufCount . " buffers?")
            return
        endif
    endif

    call ctrlspace#window#Kill(0, 1)

    tabclose

    call ctrlspace#buffers#DeleteHiddenNonameBuffers(1)
    call ctrlspace#buffers#DeleteForgottenBuffers(1)

    call ctrlspace#window#Toggle(0)
endfunction

function! ctrlspace#tabs#CollectUnsavedBuffers()
    let buffers = []

    for i in range(1, bufnr("$"))
        if getbufvar(i, "&modified") && getbufvar(i, "&modifiable") && getbufvar(i, "&buflisted")
            call add(buffers, i)
        endif
    endfor

    if empty(buffers)
        call ctrlspace#ui#Msg("There are no unsaved buffers.")
        return 0
    endif

    call ctrlspace#window#Kill(0, 1)

    tabnew

    call ctrlspace#tabs#SetTabLabel(tabpagenr(), "Unsaved buffers", 1)

    for b in buffers
        silent! exe ":b " . b
    endfor

    call ctrlspace#window#Toggle(0)
    call ctrlspace#window#Kill(0, 0)
    call s:modes.Tab.Enable()
    call ctrlspace#window#Toggle(1)
    return 1
endfunction

function! ctrlspace#tabs#CollectForgottenBuffers()
    let buffers = {}

    for t in range(1, tabpagenr("$"))
        silent! call extend(buffers, gettabvar(t, "CtrlSpaceList"))
    endfor

    let forgottenBuffers = []

    for b in keys(ctrlspace#buffers#Buffers(0))
        if !has_key(buffers, b)
            call add(forgottenBuffers, b)
        endif
    endfor

    if empty(forgottenBuffers)
        call ctrlspace#ui#Msg("There are no forgotten buffers.")
        return 0
    endif

    call ctrlspace#window#Kill(0, 1)

    tabnew

    call ctrlspace#tabs#SetTabLabel(tabpagenr(), "Forgotten buffers", 1)

    for fb in forgottenBuffers
        silent! exe ":b " . fb
    endfor

    call ctrlspace#window#Toggle(0)
    call ctrlspace#window#Kill(0, 0)
    call s:modes.Tab.Enable()
    call ctrlspace#window#Toggle(1)
    return 1
endfunction
