

pub const CompositeAnimator = struct {
    animations: [][]usize,
    elapsed: f32 = 0,
    fps: usize = 8,
    state: State = State.pause,

    pub const State = enum {
        pause,
        play,
    };
};

pub const CharacterAnimator = struct {
    headAnimation: []usize,
    bodyAnimation: []usize,
    fps: usize = 8,
    state: State = State.pause,

    pub const State = enum {
        pause,
        play
    };
};


pub const SpriteAnimator = struct {
    animation: []usize,
    frame: usize = 0,
    elapsed: f32 = 0,
    fps: usize = 8,
    state: State = State.pause,

    pub const State = enum {
        pause,
        play,
    };
};