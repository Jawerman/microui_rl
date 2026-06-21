package microui_rl

import "core:fmt"
import "core:unicode/utf8"
import mu "vendor:microui"
import rl "vendor:raylib"


// Bonus: Larger and clearer font
FONT_SIZE :: 20

init :: proc(ctx: ^mu.Context) {
	mu.init(ctx)

	// Text callbacks with corrected types
	ctx.text_width = proc(font: mu.Font, text: string) -> i32 {
		return rl.MeasureText(fmt.ctprintf("%s", text), FONT_SIZE)
	}
	ctx.text_height = proc(font: mu.Font) -> i32 {
		return FONT_SIZE
	}

	// --- STYLE ADJUSTMENT (So it's not cramped) ---
	// Increase widget padding (internal spacing)
	ctx.style.padding = 6
	ctx.style.spacing = 4
	ctx.style.title_height = FONT_SIZE + 8
}

update :: proc(ctx: ^mu.Context) {
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

draw :: proc(ctx: ^mu.Context) {
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
				FONT_SIZE,
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
	#partial switch id {
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
