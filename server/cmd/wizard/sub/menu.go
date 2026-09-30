package sub

import (
	"bit-craft/cmd/wizard/core"

	"charm.land/huh/v2"
)

// runMenu repeatedly shows a select prompt built from opts under domain,
// invoking pre (if non-nil) before each prompt and handle after each
// non-cancel choice, until the user picks cancel or the form errors out.
func runMenu(domain, title string, opts []huh.Option[action], cancel action, pre func(), handle func(action)) {
	for {
		if pre != nil {
			pre()
		}

		var ret action
		form := huh.NewForm(
			huh.NewGroup(
				huh.NewSelect[action]().
					Title(title).
					Options(opts...).
					Value(&ret),
			),
		)

		if err := form.Run(); err != nil || ret == cancel {
			core.ProcLog.Info(domain, "operation cancelled, ware!")
			return
		}

		handle(ret)
	}
}
