package microui_rl

import "core:fmt"
import "core:unicode/utf8"
import mu "vendor:microui"
import rl "vendor:raylib"


Context :: struct {
	ctx:       ^mu.Context,
	font_size: i32,
}

init :: proc(ui_context: ^Context, style: mu.Style = mu.default_style) {
	ctx := new(mu.Context)
	mu.init(ctx)

	// Text callbacks with corrected types
	ctx.text_width = proc(font: mu.Font, text: string) -> i32 {
		font_size: ^i32 = (^i32)(font)
		return rl.MeasureText(fmt.ctprintf("%s", text), font_size^)
	}
	ctx.text_height = proc(font: mu.Font) -> i32 {
		font_size: ^i32 = (^i32)(font)
		return font_size^
	}

	ctx.style^ = style
	ctx.style.font = mu.Font(&ui_context.font_size)

	ui_context.ctx = ctx
}


deinit :: proc(ui_context: ^Context) {
	free(ui_context.ctx)
}

update :: proc(ui_context: ^Context) {
	ctx := ui_context.ctx

	m := rl.GetMousePosition()
	mu.input_mouse_move(ctx, i32(m.x), i32(m.y))

	wheel := rl.GetMouseWheelMove()
	if wheel != 0 do mu.input_scroll(ctx, 0, i32(wheel * -30))

	if rl.IsMouseButtonPressed(.LEFT) do mu.input_mouse_down(ctx, i32(m.x), i32(m.y), .LEFT)
	if rl.IsMouseButtonReleased(.LEFT) do mu.input_mouse_up(ctx, i32(m.x), i32(m.y), .LEFT)
	if rl.IsMouseButtonPressed(.RIGHT) do mu.input_mouse_down(ctx, i32(m.x), i32(m.y), .RIGHT)
	if rl.IsMouseButtonReleased(.RIGHT) do mu.input_mouse_up(ctx, i32(m.x), i32(m.y), .RIGHT)

	for {
		char := rl.GetCharPressed()
		if char == 0 do break
		s := utf8.runes_to_string({char}, context.temp_allocator)
		mu.input_text(ctx, s)
	}

	_check_key(ctx, .BACKSPACE, .BACKSPACE)
	_check_key(ctx, .ENTER, .RETURN)
	_check_key(ctx, .KP_ENTER, .RETURN)
	_check_key(ctx, .LEFT_SHIFT, .SHIFT)
	_check_key(ctx, .RIGHT_SHIFT, .SHIFT)
	_check_key(ctx, .LEFT_CONTROL, .CTRL)
	_check_key(ctx, .RIGHT_CONTROL, .CTRL)
}

draw :: proc(ui_context: ^Context) {
	ctx := ui_context.ctx

	cmd: ^mu.Command
	for mu.next_command(ctx, &cmd) {
		switch variant in cmd.variant {
		case ^mu.Command_Rect:
			rl.DrawRectangle(
				variant.rect.x,
				variant.rect.y,
				variant.rect.w,
				variant.rect.h,
				_to_rl_color(variant.color),
			)

		case ^mu.Command_Text:
			rl.DrawText(
				fmt.ctprintf("%s", variant.str),
				variant.pos.x,
				variant.pos.y,
				ui_context.font_size,
				_to_rl_color(variant.color),
			)

		case ^mu.Command_Icon:
			_draw_icon(variant.id, variant.rect, _to_rl_color(variant.color))

		case ^mu.Command_Clip:
			rl.BeginScissorMode(variant.rect.x, variant.rect.y, variant.rect.w, variant.rect.h)

		case ^mu.Command_Jump:
		// next_command() already handles jumps internally,
		// follows the destination and never returns them to the caller.
		}
	}
	rl.EndScissorMode()
}

_check_key :: proc(ctx: ^mu.Context, rl_k: rl.KeyboardKey, mu_k: mu.Key) {
	if rl.IsKeyPressed(rl_k) do mu.input_key_down(ctx, mu_k)
	if rl.IsKeyReleased(rl_k) do mu.input_key_up(ctx, mu_k)
}

_to_rl_color :: proc(c: mu.Color) -> rl.Color {
	return {c.r, c.g, c.b, c.a}
}

_draw_icon :: proc(id: mu.Icon, rect: mu.Rect, color: rl.Color) {
	switch id {
	case .NONE:
	// nothing to draw for NONE
	case .CLOSE:
		s := i32(rect.w / 4)
		rl.DrawLine(rect.x + s, rect.y + s, rect.x + rect.w - s, rect.y + rect.h - s, color)
		rl.DrawLine(rect.x + s, rect.y + rect.h - s, rect.x + rect.w - s, rect.y + s, color)
	case .CHECK:
		rl.DrawRectangle(rect.x + 4, rect.y + 4, rect.w - 8, rect.h - 8, color)
	case .COLLAPSED:
		v1 := rl.Vector2{f32(rect.x + 4), f32(rect.y + 4)}
		v2 := rl.Vector2{f32(rect.x + 4), f32(rect.y + rect.h - 4)}
		v3 := rl.Vector2{f32(rect.x + rect.w - 4), f32(rect.y + rect.h / 2)}
		rl.DrawTriangle(v1, v2, v3, color)
	case .EXPANDED:
		v1 := rl.Vector2{f32(rect.x + 4), f32(rect.y + 4)}
		v2 := rl.Vector2{f32(rect.x + rect.w - 4), f32(rect.y + 4)}
		v3 := rl.Vector2{f32(rect.x + rect.w / 2), f32(rect.y + rect.h - 4)}
		rl.DrawTriangle(v1, v2, v3, color)
	case .RESIZE:
		rl.DrawLine(
			rect.x + rect.w,
			rect.y + rect.h - 4,
			rect.x + rect.w - 4,
			rect.y + rect.h,
			color,
		)
		rl.DrawLine(
			rect.x + rect.w,
			rect.y + rect.h - 8,
			rect.x + rect.w - 8,
			rect.y + rect.h,
			color,
		)
	}
}
