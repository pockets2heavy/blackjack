// Basic card & deck functionality
const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const STANDARD_DECK_SIZE = 52;
const MAX_NUM_OF_DECKS = 4;
const MAX_CAPACITY = MAX_NUM_OF_DECKS * STANDARD_DECK_SIZE;

const Suit = enum {
    clubs,
    diamonds,
    hearts,
    spades,
};

const Rank = enum {
    two,
    three,
    four,
    five,
    six,
    seven,
    eight,
    nine,
    ten,
    jack,
    queen,
    king,
    ace,
};

const Card = struct {
    suit: Suit,
    rank: Rank,

    fn suitString(self: @This()) []const u8 {
        switch (self.suit) {
            .clubs => return "clubs",
            .diamonds => return "diamonds",
            .hearts => return "hearts",
            .spades => return "spades",
        }
    }

    fn suitStringShort(self: @This()) []const u8 {
        switch (self.suit) {
            .clubs => return "C",
            .diamonds => return "D",
            .hearts => return "H",
            .spades => return "S",
        }
    }

    fn rankString(self: @This()) []const u8 {
        switch (self.rank) {
            .two => return "2",
            .three => return "3",
            .four => return "4",
            .five => return "5",
            .six => return "6",
            .seven => return "7",
            .eight => return "8",
            .nine => return "9",
            .ten => return "10",
            .jack => return "J",
            .queen => return "Q",
            .king => return "K",
            .ace => return "A",
        }
    }

    fn printCard(self: @This()) void {
        print("{s} of {s}\n", .{ self.rankString(), self.suitString() });
    }

    fn printCardShort(self: @This()) void {
        print("{s}{s}\n", .{ self.rankString(), self.suitStringShort() });
    }

    fn isFaceCard(self: @This()) bool {
        switch (self.rank) {
            .two, .three, .four, .five, .six, .seven, .eight, .nine => return false,
            else => return true,
        }
    }

    fn isFaceOrTenCard(self: @This()) bool {
        switch (self.rank) {
            .two, .three, .four, .five, .six, .seven, .eight, .nine => return false,
            else => return true,
        }
    }

    fn isAce(self: @This()) bool {
        return self.rank == .ace;
    }

    fn isTenValue(self: @This()) bool {
        switch (self.rank) {
            .two, .three, .four, .five, .six, .seven, .eight, .nine, .ace => return false,
            else => return true,
        }
    }
};

const ALL_SUITS = [4]Suit{ Suit.clubs, Suit.diamonds, Suit.hearts, Suit.spades };
const ALL_RANKS = [13]Rank{
    Rank.two,
    Rank.three,
    Rank.four,
    Rank.five,
    Rank.six,
    Rank.seven,
    Rank.eight,
    Rank.nine,
    Rank.ten,
    Rank.jack,
    Rank.queen,
    Rank.king,
    Rank.ace,
};

const cardCollection = struct {
    cards: []?Card,
    num_cards: usize,
    allocator: Allocator,

    fn printCardsShort(self: @This()) void {
        // print function for debugging/testing
        var idx: usize = 0;
        while ((idx < self.num_cards) and (self.cards[idx] != null)) {
            self.cards[idx].?.printCardShort();
            idx += 1;
        }
    }

    pub fn num_cards(self: @This()) usize {
        return self.num_cards;
    }

    pub fn initEmpty(allocator: Allocator) !cardCollection {
        var result = try allocator.alloc(?Card, MAX_CAPACITY);

        // const all_nulls = [_]?Card{null} ** MAX_CAPACITY;
        // _ = all_nulls;

        for (result, 0..) |value, i| {
            _ = value;
            result[i] = null;
        }

        return cardCollection{
            .cards = result,
            .num_cards = 0,
            .allocator = allocator,
        };
    }

    pub fn pushCard(self: *@This(), new_card: Card) !void {
        if (self.num_cards >= MAX_CAPACITY) {
            return error.CapacityReached;
        } else {
            self.cards[self.num_cards] = new_card;
            self.num_cards += 1;
        }
    }

    pub fn initStandardDeck(allocator: Allocator, num_of_decks: usize) !cardCollection {
        if (num_of_decks > 0 and num_of_decks * STANDARD_DECK_SIZE <= MAX_CAPACITY) {
            var new_deck = try initEmpty(allocator);

            var counter: usize = 0;
            while (counter < num_of_decks) {
                for (ALL_SUITS) |suit_val| {
                    for (ALL_RANKS) |rank_val| {
                        try new_deck.pushCard(Card{ .suit = suit_val, .rank = rank_val });
                    }
                }
                counter += 1;
            }
            new_deck.cards = new_deck.cards[0..new_deck.num_cards];
            return new_deck;
        } else {
            return error.InvalidNumOfDecks;
        }
    }

    pub fn shuffle(self: @This(), rand: std.rand.Random) void {
        rand.shuffle(?Card, self.cards);
    }

    pub fn popCard(self: *@This()) !Card {
        if (self.num_cards > 0) {
            const pop_card = self.cards[self.num_cards - 1];
            self.cards[self.num_cards - 1] = null;
            self.num_cards -= 1;
            self.cards = self.cards[0..self.num_cards];
            return pop_card.?;
        }
        return error.CardCollectionEmpty;
    }

    pub fn popSendCardTo(self: *@This(), target: *cardCollection) !void {
        const card = try self.popCard();

        try target.pushCard(card);
    }

    pub fn free(self: *@This()) void {
        self.allocator.free(self.cards);
    }
};
