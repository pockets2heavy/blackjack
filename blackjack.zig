const print = std.debug.print;

const std = @import("std");
const Allocator = std.mem.Allocator;

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

// const RankValueType = union(enum) {
//     two: u8,
//     three: u8,
//     four: u8,
//     five: u8,
//     six: u8,
//     seven: u8,
//     eight: u8,
//     nine: u8,
//     ten: u8,
//     jack: u8,
//     queen: u8,
//     king: u8,
//     ace: .{
//         .lower,
//         .upper,
//     },
// };

// const RankValueBlackjack = RankValueType{
//     .two = 2,
//     .three = 3,
//     .four = 4,
//     .five = 5,
//     .six = 6,
//     .seven = 7,
//     .eight = 8,
//     .nine = 9,
//     .ten = 10,
//     .jack = 10,
//     .queen = 10,
//     .king = 10,
//     .ace = .{
//         .lower = 1,
//         .upper = 11,
//     },
// };

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

//constants
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

const STANDARD_DECK_SIZE = 52;
const MAX_NUM_OF_DECKS = 4;
const MAX_CAPACITY = MAX_NUM_OF_DECKS * STANDARD_DECK_SIZE;

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

//blackjack main skeleton
// pub fn main() !void {

//     var current_state = GAME_STATE.start;

//     while(current_state!=GAME_STATE.quit){
//         switch(current_state){
//             start =>,
//             setup =>,
//             betting =>,
//             deal=>,
//             scoring=>,
//             payout=>,
//             end_game=>,
//             quit=>,

//         }

//     }
// }

// blackjack  constants & structs
const ACE_LOWER_VALUE = 1;
const ACE_UPPER_VALUE = 11;
const MAX_PLAYERS = 4;
const MIN_BANK = 50;
const MAX_BANK = 255;
const Action = enum {
    hit,
    stand,
    double,
    split,
    surrender,
    insurance,
};
const Score = union(enum(u8)) {
    score: u8,
    blackjack,
};
const GameSetupConfig = struct {
    players: u8,
    num_of_decks: u8,
    bank_size: u8,

    pub fn init(players: u8, num_of_decks: u8, bank_size: u8) @This() {
        return @This(){
            .players = players,
            .num_of_decks = num_of_decks,
            .bank_size = bank_size,
        };
    }
};
const GameState = union(enum) {
    start,
    setup,
    betting: GameSetupConfig,
    deal,
    scoring,
    payout,
    end_game,
    quit,
};
const PlayerBanks = struct {
    banks: []u8,
    pub fn init(config: GameSetupConfig, allocator: Allocator) !PlayerBanks {
        var result = try allocator.alloc(u8, config.players);
        for (result, 0..) |val, i| {
            _ = val;
            result[i] = config.bank_size;
        }
        return PlayerBanks{ .banks = result[0..] };
    }
    pub fn makeBet(self: @This(), player: u8, bet_amount: u8) !void {
        if (self.banks[player] >= bet_amount) {
            self.banks[player] = self.banks[player] - bet_amount;
        } else {
            return error.InsufficientFundsError;
        }
    }
    pub fn payout(self: @This(), player: u8, pay: u8) void {
        self.banks[player] = self.banks[player] + pay;
    }

    fn printDebug(self: @This()) void {
        for (self.banks, 0..) |value, i| {
            print("Player {}: {}\n", .{ i, value });
        }
    }
};

// functions
fn getNumericMenuInput() !u8 {
    const stdin = std.io.getStdIn().reader();

    const bare_line = try stdin.readUntilDelimiterAlloc(
        std.heap.page_allocator,
        '\n',
        8192,
    );
    defer std.heap.page_allocator.free(bare_line);

    const line = std.mem.trim(u8, bare_line, "\r");
    const input = std.fmt.parseInt(u8, line, 10) catch error.ParseIntError;

    return input;
}

pub fn startMenu() !GameState {
    // _ = current_state;
    const stdout = std.io.getStdOut().writer();

    try stdout.writeAll("\n***BLACKJACK START MENU***\n(1) Start New Game\n(2) Quit\n\nSelection: ");

    const input = getNumericMenuInput() catch {
        try stdout.writeAll("Please make a valid selection.\n");
        return GameState.start;
    };

    if (input == 1) {
        return GameState.setup;
    } else if (input == 2) {
        return GameState.quit;
    } else {
        return GameState.start;
    }
}

pub fn newGameSetup() !GameState {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n\nEnter Number of Players (1-{}): ", .{MAX_PLAYERS});

    const players = getNumericMenuInput() catch {
        try stdout.writeAll("Please enter a valid number of players.\n");
        return GameState.setup;
    };
    if (players < 1 or players > MAX_PLAYERS) {
        try stdout.writeAll("Please enter a valid number of players.\n");
        return GameState.setup;
    }

    try stdout.print("\n\nEnter Number of Decks (1-{}): ", .{MAX_NUM_OF_DECKS});

    const num_of_decks = getNumericMenuInput() catch {
        try stdout.writeAll("Please enter a valid number of decks.\n");
        return GameState.setup;
    };

    if (num_of_decks < 1 or num_of_decks > MAX_NUM_OF_DECKS) {
        try stdout.writeAll("Please enter a valid number of decks.\n");
        return GameState.setup;
    }

    try stdout.print("\n\nEnter Bank Size ({}-{}): ", .{ MIN_BANK, MAX_BANK });
    const bank_size = getNumericMenuInput() catch {
        try stdout.writeAll("Please enter a valid bank size.\n");
        return GameState.setup;
    };

    if (bank_size < MIN_BANK or bank_size > MAX_BANK) {
        try stdout.writeAll("Please enter a valid bank size.\n");
        return GameState.setup;
    }

    // const new_config = GameSetupConfig{ .players = players, .num_of_decks = num_of_decks, .bank_size = bank_size };
    const new_config = GameSetupConfig.init(players, num_of_decks, bank_size);

    return GameState{ .betting = new_config };
}

pub fn takeBets(player_banks: PlayerBanks) !GameState {
    const stdout = std.io.getStdOut().writer();
    try stdout.writeAll("\n\n***BETTING***\n\n");

    for (player_banks.banks, 0..) |value, i| {
        try stdout.print("\n\n PLAYER {} AVAILABLE BANK: {}\nPlease Enter Your Bet (0-{}): ", .{ i + 1, value, value });

        const bet_amount = getNumericMenuInput() catch blk: {
            try stdout.writeAll("Invalid bet default to 0.\n");
            break :blk 0;
        };

        player_banks.makeBet(@as(u8, i), bet_amount) catch {
            player_banks.makeBet(@as(u8, i), 0);
        };
    }

    return GameState.deal;
}

pub fn valueBlackjack(card: Card) u8 {
    switch (card.rank) {
        .two => return 2,
        .three => return 3,
        .four => return 4,
        .five => return 5,
        .six => return 6,
        .seven => return 7,
        .eight => return 8,
        .nine => return 9,
        .ten => return 10,
        .jack => return 10,
        .queen => return 10,
        .king => return 10,
        .ace => return 1,
    }
}

pub fn checkForBlackjack(hand: cardCollection) bool {
    return (hand.num_cards == 2) and ((hand.cards[0].?.isAce() and hand.cards[1].?.isTenValue()) or (hand.cards[0].?.isTenValue() and hand.cards[1].?.isAce()));
}

fn createScoreList(hand: cardCollection, allocator: Allocator) !std.ArrayList(u8) {
    var scores = std.ArrayList(u8).init(allocator);
    try scores.append(0);

    var cards_idx: usize = 0;

    while ((cards_idx < hand.num_cards) and (hand.cards[cards_idx] != null)) {
        if (hand.cards[cards_idx].?.rank != Rank.ace) {
            for (scores.items, 0..) |val, i| {
                _ = val;
                scores.items[i] += valueBlackjack(hand.cards[cards_idx].?);
            }
        } else {
            for (scores.items, 0..) |val, i| {
                _ = val;
                scores.items[i] += ACE_LOWER_VALUE;
            }
            try scores.appendSlice(scores.items);

            var new_idx: usize = scores.items.len / 2;
            while (new_idx < scores.items.len) {
                scores.items[new_idx] += ACE_UPPER_VALUE - ACE_LOWER_VALUE;
                new_idx += 1;
            }
        }
        cards_idx += 1;
    }

    return scores;
}

pub fn bestScore(hand: cardCollection, allocator: Allocator) !u8 {
    const score_list = try createScoreList(hand, allocator);
    // defer allocator.free(score_list);

    var best_score: u8 = 0;
    for (score_list.items) |val| {
        if (val <= 21 and val > best_score) {
            best_score = val;
        }
    }
    return best_score;
}

// tests
test "player banks" {
    const stdout = std.io.getStdOut().writer();
    const new_config = GameSetupConfig.init(2, 4, 200);

    var curr_state: GameState = GameState{ .betting = new_config };

    const allocator = std.heap.page_allocator;

    // var result = try allocator.alloc(u8, curr_state.betting.players);
    // for (result, 0..) |val, i| {
    //     _ = val;
    //     result[i] = curr_state.betting.bank_size;
    // }
    const player_banks: PlayerBanks = try PlayerBanks.init(curr_state.betting, allocator);
    player_banks.printDebug();

    player_banks.makeBet(0, 50) catch {
        try stdout.writeAll("Insufficient funds.");
    };
    player_banks.makeBet(1, 100) catch {
        try stdout.writeAll("Insufficient funds.");
    };

    player_banks.printDebug();

    player_banks.payout(0, 50);

    player_banks.payout(1, 100);

    player_banks.printDebug();

    // curr_state = takeBets(&player_banks);

    // player_banks.printDebug();
}

// test "setup" {
//     var curr_state: GameState = GameState.setup;
//     while (curr_state != GameState.quit) {
//         curr_state = try newGameSetup();
//         switch (curr_state) {
//             .betting => {
//                 print("players: {}\n", .{curr_state.betting.players});
//                 curr_state = GameState.quit;
//             },
//             else => {},
//         }
//     }
// }

// test "start menu" {
//     var curr_state = GameState.start;

//     while (curr_state != GameState.quit) {
//         curr_state = try startMenu();
//     }
// }

// test "scores" {
//     const card1 = Card{
//         .suit = Suit.clubs,
//         .rank = Rank.ace,
//     };

//     const card2 = Card{
//         .suit = Suit.clubs,
//         .rank = Rank.nine,
//     };

//     const card3 = Card{
//         .suit = Suit.diamonds,
//         .rank = Rank.ace,
//     };

//     const allocator = std.heap.page_allocator;
//     var new_hand = try cardCollection.initEmpty(allocator);

//     try new_hand.pushCard(card1);
//     try new_hand.pushCard(card2);
//     try new_hand.pushCard(card3);

//     const best_score = try bestScore(new_hand, allocator);

//     try std.testing.expect(best_score == 21);

//     // var scores2 = try createScoreList(new_hand, allocator2);

//     // for (scores2.items) |value| {
//     //     print("{}\n", .{value});
//     // }

//     // var new_hand2 = try cardCollection.initEmpty(allocator);

//     // var scores3 = try createScoreList(new_hand2, allocator2);

//     // for (scores3.items) |value| {
//     //     print("{}\n", .{value});
//     // }

//     // const allocator = std.heap.page_allocator;
//     // var scores = std.ArrayList(u8).init(allocator);
//     // try scores.append(1);
//     // try scores.append(11);

//     // for (scores.items, 0..) |val, i| {
//     //     _ = val;
//     //     scores.items[i] += ACE_LOWER_VALUE;
//     // }

//     // try scores.appendSlice(scores.items);

//     // var idx: usize = scores.items.len / 2;

//     // while (idx < scores.items.len) {
//     //     scores.items[idx] += ACE_UPPER_VALUE - ACE_LOWER_VALUE;
//     //     idx += 1;
//     // }

//     // for (scores.items) |value| {
//     //     print("{}\n", .{value});
//     // }

//     // a_score_list.deinit();
//     // list_of_score_lists.deinit();

//     // var list_scores = std.ArrayList(u8).init(allocator);

// }

// test "blackjack test" {
//     const card1 = Card{
//         .suit = Suit.clubs,
//         .rank = Rank.ace,
//     };

//     const card2 = Card{
//         .suit = Suit.clubs,
//         .rank = Rank.ten,
//     };
//     const allocator = std.heap.page_allocator;
//     var new_hand = try cardCollection.initEmpty(allocator);

//     try new_hand.pushCard(card1);
//     try new_hand.pushCard(card2);

//     new_hand.printCardsShort();

//     const check1 = checkForBlackjack(new_hand);

//     print("is this blackjack?: {}\n", .{check1});

//     new_hand.free();

//     const card3 = Card{
//         .suit = Suit.clubs,
//         .rank = Rank.ace,
//     };

//     const card4 = Card{
//         .suit = Suit.clubs,
//         .rank = Rank.nine,
//     };

//     var new_hand2 = try cardCollection.initEmpty(allocator);

//     try new_hand2.pushCard(card3);
//     try new_hand2.pushCard(card4);

//     new_hand2.printCardsShort();

//     const check2 = checkForBlackjack(new_hand2);

//     print("is this blackjack?: {}\n", .{check2});
// }

// test "suits test" {

//     // const test_1 = @typeInfo(Suit).Enum.fields[0].name;

//     // print("{s}\n", .{test_1});

//     // const allSuits = [4]Suit{ Suit.clubs, Suit.diamonds, Suit.hearts, Suit.spades };
//     // for (allSuits) |val| {
//     //     print("{}\n", .{val});
//     // }

//     // const testCard_1 = Card{
//     //     .suit = Suit.clubs,
//     //     .rank = Rank.two,
//     // };
//     // _ = testCard_1;

//     // const testCard_2 = Card{
//     //     .suit = allSuits[0],
//     //     .rank = Rank.two,
//     // };
//     // _ = testCard_2;

//     // const testCard_3 = Card{
//     //     .suit = allSuits[0],
//     //     .rank = Rank.ten,
//     // };
//     // // _ = testCard_3;
//     // var buffer: [10]u8 = undefined;
//     // var fpa = std.heap.FixedBufferAllocator.init(&buffer);
//     // const allocator = fpa.allocator();

//     // const allocator = std.heap.page_allocator;
//     // var new_deck = try cardCollection.initEmpty(allocator);
//     // print("number of cards in collection: {}\n", .{new_deck.num_cards});
//     // print("capacity of collection: {}\n", .{new_deck.cards.len});

//     // var new_deck = try cardCollection.initStandardDeck(allocator, 1);
//     // print("number of cards in collection: {}\n", .{new_deck.num_cards});

//     // for (new_deck.cards) |this_card| {
//     //     this_card.?.printCard();
//     // }

//     // var prng = std.rand.DefaultPrng.init(blk: {
//     //     var seed: u64 = undefined;
//     //     try std.os.getrandom(std.mem.asBytes(&seed));
//     //     break :blk seed;
//     // });
//     // const rand = prng.random();

//     // new_deck.shuffle(rand);

//     // rand.shuffle(?Card, new_deck.cards);

//     // new_deck.printCardsShort();

//     // print("********\n\n", .{});

//     // var buffer: [1000]u8 = undefined;
//     // var fpa = std.heap.FixedBufferAllocator.init(&buffer);
//     // const allocator2 = fpa.allocator();

//     // var new_hand = try cardCollection.initEmpty(allocator2);

//     // try new_deck.popSendCardTo(&new_hand);

//     // new_deck.printCardsShort();
//     // print("********\n\n", .{});
//     // new_hand.printCardsShort();
//     // const popped = try new_deck.popCard();

//     // popped.printCardShort();

//     // print("********\n\n", .{});

//     // for (new_deck.cards) |this_card| {
//     //     this_card.?.printCardShort();
//     // }

//     // print("capacity in collection: {}\n", .{new_deck.cards.capacity});

//     // const new_card = Card{
//     //     .suit = Suit.clubs,
//     //     .rank = Rank.two,
//     // };

//     // try new_deck.pushCard(new_card);
//     // try new_deck.pushCard(new_card);
//     // print("number of cards in collection: {}\n", .{new_deck.num_cards});
//     // print("capacity of collection: {}\n", .{new_deck.cards.len});
//     // print("cards in collection: {}\n", .{new_deck.cards.items.len});
//     // print("capacity in collection: {}\n", .{new_deck.cards.capacity});
//     // _ = new_card;
//     // var new_deck2 = try std.ArrayList(*Card).initCapacity(allocator, 10);
//     // try new_deck2.append(@constCast(&new_card));
//     // try new_deck2.append(@constCast(&new_card));
//     // print("cards in new collection: {}\n", .{new_deck2.items.len});
//     // try new_deck.cards.append(new_card);
//     // const new_deck = try cardCollection.initStandardDeck(allocator);

//     // for (new_deck.cards.items) |this_card| {
//     //     this_card.printCard();
//     // }

//     // const new_card = Card{
//     //     .suit = Suit.clubs,
//     //     .rank = Rank.two,
//     // };

//     // new_card.printCard();
// }
// // const test_2 = @typeInfo(Suit).Enum.fields;
