const print = std.debug.print;

const std = @import("std");
const Allocator = std.mem.Allocator;

const cards = @import("cards.zig");

const MAX_NUM_OF_DECKS = cards.MAX_NUM_OF_DECKS;

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

const PlayerBet = struct {
    player_n: u8,
    bet: u8,
    split: bool = false,
    double: bool = false,
    insurance: bool = false,
    pub fn init(player_n: u8, bet: u8) @This() {
        return @This(){
            .player_n = player_n,
            .bet = bet,
        };
    }
};
// std.ArrayList(u8)

const GameState = union(enum) {
    start,
    setup,
    betting: GameSetupConfig,
    deal: std.ArrayList(PlayerBet),
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

    pub fn getPlayerBank(self: @This(), player: u8) !u8 {
        if (player >= self.banks.len) {
            return error.InvalidPlayerError;
        }

        return self.banks[player];
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

    var idx: u8 = 0;

    while (idx < player_banks.banks.len) {
        try stdout.print("\n\n PLAYER {} AVAILABLE BANK: {!}\nPlease Enter Your Bet (0-{!}): ", .{ idx, player_banks.getPlayerBank(idx), player_banks.getPlayerBank(idx) });

        const bet_amount = getNumericMenuInput() catch blk: {
            try stdout.writeAll("Invalid bet default to 0.\n");
            break :blk 0;
        };

        player_banks.makeBet(idx, bet_amount) catch {
            try player_banks.makeBet(idx, 0);
        };

        idx += 1;
    }

    return GameState.deal;
}

pub fn valueBlackjack(card: cards.Card) u8 {
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

pub fn checkForBlackjack(hand: cards.cardCollection) bool {
    return (hand.num_cards == 2) and ((hand.cards[0].?.isAce() and hand.cards[1].?.isTenValue()) or (hand.cards[0].?.isTenValue() and hand.cards[1].?.isAce()));
}

fn createScoreList(hand: cards.cardCollection, allocator: Allocator) !std.ArrayList(u8) {
    var scores = std.ArrayList(u8).init(allocator);
    try scores.append(0);

    var cards_idx: usize = 0;

    while ((cards_idx < hand.num_cards) and (hand.cards[cards_idx] != null)) {
        if (hand.cards[cards_idx].?.rank != cards.Rank.ace) {
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

pub fn bestScore(hand: cards.cardCollection, allocator: Allocator) !u8 {
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

test "take bets" {
    const new_config = GameSetupConfig.init(2, 4, 200);
    var curr_state: GameState = GameState{ .betting = new_config };
    const allocator = std.heap.page_allocator;
    const player_banks: PlayerBanks = try PlayerBanks.init(curr_state.betting, allocator);
    curr_state = try takeBets(player_banks);

    const player_0 = try player_banks.getPlayerBank(0);
    const player_1 = try player_banks.getPlayerBank(1);

    try std.testing.expect(player_0 == 150);
    try std.testing.expect(player_1 == 100);
}
// test "player banks" {
//     const stdout = std.io.getStdOut().writer();
//     const new_config = GameSetupConfig.init(2, 4, 200);

//     var curr_state: GameState = GameState{ .betting = new_config };

//     const allocator = std.heap.page_allocator;

//     // var result = try allocator.alloc(u8, curr_state.betting.players);
//     // for (result, 0..) |val, i| {
//     //     _ = val;
//     //     result[i] = curr_state.betting.bank_size;
//     // }
//     const player_banks: PlayerBanks = try PlayerBanks.init(curr_state.betting, allocator);
//     player_banks.printDebug();

//     player_banks.makeBet(0, 50) catch {
//         try stdout.writeAll("Insufficient funds.");
//     };
//     player_banks.makeBet(1, 100) catch {
//         try stdout.writeAll("Insufficient funds.");
//     };

//     player_banks.printDebug();

//     player_banks.payout(0, 50);

//     player_banks.payout(1, 100);

//     player_banks.printDebug();

//     // curr_state = takeBets(&player_banks);

//     // player_banks.printDebug();
// }

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
