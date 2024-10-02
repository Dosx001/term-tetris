const std = @import("std");

const Shape = enum {
    I,
    J,
    L,
    O,
    S,
    T,
    Z,
};

pub const Bag = struct {
    shapes: [7]Shape,
    idx: u8,
    pub fn init() Bag {
        var bag = Bag{
            .shapes = [_]Shape{ Shape.I, Shape.J, Shape.L, Shape.O, Shape.S, Shape.T, Shape.Z },
            .idx = 7,
        };
        std.crypto.random.shuffle(Shape, bag.shapes[0..bag.shapes.len]);
        return bag;
    }
    pub fn grab(self: *Bag) Shape {
        self.idx -= 1;
        const shape = self.shapes[self.idx];
        if (self.idx == 0) {
            self.idx = 7;
            std.crypto.random.shuffle(Shape, self.shapes[0..self.shapes.len]);
        }
        return shape;
    }
};
