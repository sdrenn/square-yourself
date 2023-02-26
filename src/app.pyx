import random
import pyglet
from pyglet import shapes
from pyglet.window import key
from collections import namedtuple

Point = namedtuple('Point', ['x', 'y'])

config = pyglet.gl.Config(double_buffer=True)

display = pyglet.canvas.Display()
screen = display.get_default_screen()
WIDTH = screen.width // 2
HEIGHT = screen.height // 2
fullscreen = False

window = pyglet.window.Window(
    config=config,
    width=WIDTH,
    height=HEIGHT,
    fullscreen=fullscreen,
    caption='SQUARE YOURSELF'
)
window.set_location(screen.width // 2 - WIDTH // 2, screen.height // 2 - HEIGHT // 2)

SCALE = window.width // 960 
PLAYER_X = 100 * SCALE
PLAYER_SIZE = Point(50 * SCALE, 50 * SCALE)
ENEMY_SIZE = Point(50 * SCALE, 50 * SCALE)
DOOR_SIZE = Point(100 * SCALE, 150 * SCALE)
GROUND_WIDTH = 1 * SCALE
FONT_SIZE = 36 * SCALE
SPEED = 6 * SCALE
JUMP_SPEED = 23 * SCALE
FALL_SPEED = 1 * SCALE
TIME = 120
GROUND_LEVEL = 50 * SCALE
DOOR_PLACE = 20000 * SCALE
SQUARE_PLACE = 1000 * SCALE
SQUARE_SHIFT = 300 * SCALE


# window = pyglet.window.Window(WIDTH, HEIGHT)
batch = pyglet.graphics.Batch()
keys = set()


circle = shapes.Rectangle(PLAYER_X, GROUND_LEVEL, PLAYER_SIZE.x, PLAYER_SIZE.y, color=(50, 225, 30), batch=batch)
squares = [
    shapes.Rectangle(WIDTH, GROUND_LEVEL, ENEMY_SIZE.x, ENEMY_SIZE.y, color=(55, 55, 255), batch=batch)
    for _ in range(4)
]
line = shapes.Line(0, GROUND_LEVEL, WIDTH, GROUND_LEVEL, width=GROUND_WIDTH, batch=batch)
door = shapes.Rectangle(WIDTH, GROUND_LEVEL, DOOR_SIZE.x, DOOR_SIZE.y, color=(255, 55, 100), batch=batch)


label = pyglet.text.Label(
    'GAME OVER',
    font_name='Times New Roman',
    font_size=FONT_SIZE,
    x=window.width//2, y=window.height//2,
    anchor_x='center', anchor_y='center'
)

count_label = pyglet.text.Label(
    '0',
    font_name='Times New Roman',
    font_size=FONT_SIZE,
    x=0, y=window.height,
    anchor_x='left', anchor_y='top',
    batch=batch
)
speed_label = pyglet.text.Label(
    str(TIME),
    font_name='Times New Roman',
    font_size=36,
    x=window.width, y=window.height,
    anchor_x='right', anchor_y='top',
    batch=batch
)


class Player:
    def __init__(self, jump_speed, fall_speed):
        self.x = 0
        self.y = 0
        self.speed = 0
        self.jump_speed = jump_speed
        self.fall_speed = fall_speed

    def jump(self):
        if self.y > 0:
            return
        self.speed = self.jump_speed

    def update(self):
        self.y += self.speed
        if self.y < 0:
            self.y = 0
        if self.y > 0:
            self.speed -= self.fall_speed
        return self.y


def collide(square1, square2):
    bourder = 0
    if square2.x + bourder <= square1.x <= square2.x + square2.width - bourder:
        if square2.y <= square1.y <= square2.y + square2.height:
            return True
    if square1.x + bourder <= square2.x <= square1.x + square1.width - bourder:
        if square1.y <= square2.y <= square1.y + square1.height:
            return True
    return False


class Squares:
    def __init__(self, speed, squares, door):
        self.speed = speed
        self.squares = squares
        self.door = door
        self.door.x = DOOR_PLACE
        for square in self.squares:
            self.random_start(square)

    def random_start(self, square, range_start=0, range_end=SQUARE_PLACE):
        max_x = max((sq.x for sq in self.squares))
        x = WIDTH + random.randint(range_start, range_end)
        if x > max_x + SQUARE_SHIFT:
            square.x = x
        else:
            square.x = max_x + SQUARE_SHIFT
        if self.collide_door(square):
            square.x += SQUARE_SHIFT * 2

    def collide(self, player):
        return any(collide(square, player) for square in self.squares)

    def collide_door(self, player):
        return collide(player, self.door)

    def update(self):
        for square in self.squares:
            square.x -= self.speed
            if square.x < 0:
                self.random_start(square)
                game.count += 1

        self.door.x -= self.speed
        if self.door.x < 0:
            self.door.x = DOOR_PLACE


class Game:
    def __init__(self):
        self.speed = SPEED
        self.jump_speed = JUMP_SPEED
        self.fall_speed = FALL_SPEED
        self.time = TIME
        self.score = 0
        self.cooldown = False

    def level_up(self, score):
        self.score += score
        self.time += 20
        return self.time

    def gameover_cooldown(self, dt):
        self.cooldown = not self.cooldown

    def reset(self):
        self.end = False
        self.player = Player(self.jump_speed, self.fall_speed)
        self.squares = Squares(self.speed, squares, door)
        self.count = 0
        if self.time > 190:
            for square in squares:
                square.color = (255, 30, 30)
        pyglet.clock.unschedule(update)
        pyglet.clock.schedule_interval_soft(update, 1 / self.time)


game = Game()


@window.event
def on_draw():
    window.clear()
    batch.draw()
    if game.end:
        label.draw()


@window.event
def on_key_press(symbol, modifiers):
    keys.add(symbol)
    if symbol == key.SPACE:
        if game.end and not game.cooldown:
            print('RESTART')
            game.reset()
        else:
            game.player.jump()
    elif symbol == key.F11:
        pass
        # window.set_fullscreen(fullscreen=not window.fullscreen, screen=None, mode=None, width=None, height=None) 


@window.event
def on_key_release(symbol, modifiers):
    keys.discard(symbol)


def update(dt):
    if game.end:
        pyglet.clock.unschedule(update)
        game.gameover_cooldown(None)
        pyglet.clock.schedule_once(game.gameover_cooldown, 0.1)
        return
    if key.SPACE in keys:
        game.player.jump()
    game.squares.update()
    y = game.player.update()
    circle.y = GROUND_LEVEL + y
    count_label.text = str(game.score + game.count)
    if game.squares.collide(circle):
        game.end = True
        game.score = 0
        label.text = 'GAME OVER'
        print('COUNT:', game.score + game.count)
    if game.squares.collide_door(circle):
        game.end = True
        speed = game.level_up(game.count)
        label.text = 'YOU WON'
        speed_label.text = str(speed)
        print('COUNT:', game.count)


def main():
    game.reset()
    pyglet.app.run()


if __name__ == '__main__':
    main()
