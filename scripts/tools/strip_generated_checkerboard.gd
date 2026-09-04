extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("Usage: strip_generated_checkerboard.gd <source.png> <destination.png>")
		quit(2)
		return

	var image := Image.load_from_file(args[0])
	if image == null or image.is_empty():
		push_error("Could not load source image: %s" % args[0])
		quit(3)
		return

	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue := PackedInt32Array()

	for x in range(width):
		queue.append(x)
		queue.append((height - 1) * width + x)
	for y in range(1, height - 1):
		queue.append(y * width)
		queue.append(y * width + width - 1)

	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		if visited[index] != 0:
			continue
		visited[index] = 1

		var x := index % width
		var y := index / width
		var pixel := image.get_pixel(x, y)
		var darkest: float = minf(pixel.r, minf(pixel.g, pixel.b))
		var lightest: float = maxf(pixel.r, maxf(pixel.g, pixel.b))
		if darkest < 0.92 or lightest - darkest > 0.035:
			continue

		image.set_pixel(x, y, Color(pixel.r, pixel.g, pixel.b, 0.0))
		if x > 0:
			queue.append(index - 1)
		if x + 1 < width:
			queue.append(index + 1)
		if y > 0:
			queue.append(index - width)
		if y + 1 < height:
			queue.append(index + width)

	DirAccess.make_dir_recursive_absolute(args[1].get_base_dir())
	var error := image.save_png(args[1])
	if error != OK:
		push_error("Could not save destination image: %s" % args[1])
		quit(4)
		return

	quit()
