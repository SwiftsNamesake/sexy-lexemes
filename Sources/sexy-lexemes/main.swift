// import Foundation

// TODO: Unit tests

struct ParseError {
  let error: String
}

// TODO: Context-sensitive grammars

// "var x = 20"
// then(then(then(then(literal("var"), spaces), identifier), spaces), literal("="))

struct ParseState {
  let input: String
  // "1 + 2 = 3"
  var cursor: Int // TODO: Simplify splicing and cursor stuff, maybe store String.Index directly?
  // TODO: Add helper functions for getting substrings
  // TODO: Deal with end-of-input
  // var value: T

  func advanced(by step: Int) -> ParseState {
    return ParseState(input: self.input, cursor: self.cursor + step)
  }

  // func consume(count: Int) -> (ParseState, String) {}

  // func consume() -> ParseState
}

enum ParseResult<T> {
  case success(ParseState, T)
  case failure(ParseError)
}

struct Parser<T> {
  var run: (ParseState) -> ParseResult<T>

  // func then() -> Parser
}

func literal(_ matching: String) -> Parser<String> {
  return Parser { state in
    // let substring = state.input.index(state.input.startIndex)
    let start = state.input.index(state.input.startIndex, offsetBy: state.cursor)
    let end = state.input.index(state.input.startIndex, offsetBy: state.cursor + matching.count)
    let substring = state.input[start ..< end]
    if substring == matching {
      return .success(ParseState(input: state.input, cursor: state.cursor + matching.count), matching)
    } else {
      print(substring, substring.count)
      return .failure(ParseError(error: "Does not match literal"))
    }
  }
}

// let spaces: Parser<()> = Parser { state in }

enum Digit: Int, RawRepresentable {
  case zero  = 0
  case one   = 1
  case two   = 2
  case three = 3
  case four  = 4
  case five  = 5
  case six   = 6
  case seven = 7
  case eight = 8
  case nine  = 9
}

// TODO: Rename
// TODO: Sexier FP implementation
func fromDigits(_ digits: [Digit]) -> Int {
  print("fromDigits")
  var n = 0
  var base = 1
  for (position, digit) in digits.reversed().enumerated() {
    // n += digit.rawValue * Int(pow(10, Float(position)))
    n += digit.rawValue * base
    base *= 10
  }
  return n
}

//let digit = oneOf([ 
//  0 *> .zero,  1 *> .one,   2 *> .two,
//  3 *> .three, 4 *> .four,  5 *> .five,
//  6 *> .six,   7 *> .seven, 8 *> .eight,
//  9 *> .nine,
//])

let digit: Parser<Digit> = Parser { state in
  let start = state.input.index(state.input.startIndex, offsetBy: state.cursor)
  let end = state.input.index(state.input.startIndex, offsetBy: state.cursor + 1)
  
  switch state.input[start ..< end] {
    case "0": return .success(state.advanced(by: 1), .zero)
    case "1": return .success(state.advanced(by: 1), .one)
    case "2": return .success(state.advanced(by: 1), .two)
    case "3": return .success(state.advanced(by: 1), .three)
    case "4": return .success(state.advanced(by: 1), .four)
    case "5": return .success(state.advanced(by: 1), .five)
    case "6": return .success(state.advanced(by: 1), .six)
    case "7": return .success(state.advanced(by: 1), .seven)
    case "8": return .success(state.advanced(by: 1), .eight)
    case "9": return .success(state.advanced(by: 1), .nine)
    default: return .failure(ParseError(error: String(state.input[start ..< end])))
  }
}

func many1<T>(_ parser: Parser<T>) -> Parser<[T]> {
  return Parser { state in
    guard case var .success(latest, value) = parser.run(state) else {
      return .failure(ParseError(error: "failed to parse a single value in many1"))
    }

    var values = [value]
    while case let .success(next, value) = parser.run(latest) {
      latest = next
      values.append(value)
    }

    return .success(latest, values)
  }
}

func many<T>(_ parser: Parser<T>) -> Parser<[T]> {
  return Parser { state in
    var values: [T] = []
    var latest = state
    while case let .success(next, value) = parser.run(latest) {
      values.append(value)
      latest = next
    }
    return .success(latest, values)
  }
}

func oneOf<T>(_ parsers: [Parser<T>]) -> Parser<T> {
  return Parser { state in
    for parser in parsers {
      if case let .success(next, value) = parser.run(state) {
        return .success(next, value)
      }
    }
    return .failure(ParseError(error: "oneOf no parsers succeeded"))
  }
}

// func optional<T>(_ parser: Parser<T>) -> Parser<T?> {}

// func takeWhile(_ f: (Character) -> Bool) -> Parser<String> {}

/// Combines two parsers sequentially
func then<T, U>(_ a: Parser<T>, _ b: Parser<U>) -> Parser<(T, U)> {
  return Parser { initial in
    guard case let .success(first, av) = a.run(initial) else { return .failure(ParseError(error: "error")) }
    guard case let .success(second, bv) = b.run(first) else { return .failure(ParseError(error: "error")) }
    return .success(second, (av, bv))
  }
}

// func sepBy() -> Parser<T[]>

// TODO: Combinators (& Operators)
// *>
// <*
// <*>
// <$>
// <|>
// pure

let x = literal("def")
let y = literal(" hello")
// print(parse(input: "def hello", parser: then(x, y)))

let integer = map(fromDigits, many1(digit))

print(parse(input: "1050 bla", parser: many1(digit)))
print(parse(input: "1050 bla", parser: integer))

// Parses an integer

func map<T, U>(_ f: @escaping (T) -> U, _ parser: Parser<T>) -> Parser<U> {
  return Parser { state in
    switch parser.run(state) {
      case let .success(new, value): return .success(new, f(value))
      case let .failure(error): return .failure(error)
    }
  }
}

func parse<T>(input: String, parser: Parser<T>) -> ParseResult<T> {
  return parser.run(.init(input: input, cursor: 0))
}

// TODO: WaveFront OBJ parser
