//! A library for Operational Transformation
//!
//! Operational transformation (OT) is a technology for supporting a range of
//! collaboration functionalities in advanced collaborative software systems.
//! [[1]](https://en.wikipedia.org/wiki/Operational_transformation)
//!
//! When working on the same document over the internet concurrent operations
//! from multiple users might be in conflict. **Operational Transform** can help
//! to resolve conflicts in such a way that docuemnts stay in sync.
//!
//! The basic operations that are supported are:
//! - Retain(n): Move the cursor `n` positions forward
//! - Delete(n): Delete `n` characters at the current position
//! - Insert(s): Insert the string `s` at the current position
//!
//! This library can be  used to...
//!
//! ... compose sequences of operations:
//! ```rust
//! use operational_transform::OperationSeq;
//!
//! let mut a = OperationSeq::default();
//! a.insert("abc");
//! let mut b = OperationSeq::default();
//! b.retain(3);
//! b.insert("def");
//! let after_a = a.apply("").unwrap();
//! let after_b = b.apply(&after_a).unwrap();
//! let c = a.compose(&b).unwrap();
//! let after_ab = a.compose(&b).unwrap().apply("").unwrap();
//! assert_eq!(after_ab, after_b);
//! ```
//!
//! ... transform sequences of operations
//! ```rust
//! use operational_transform::OperationSeq;
//!
//! let s = "abc";
//! let mut a = OperationSeq::default();
//! a.retain(3);
//! a.insert("def");
//! let mut b = OperationSeq::default();
//! b.retain(3);
//! b.insert("ghi");
//! let (a_prime, b_prime) = a.transform(&b).unwrap();
//! let ab_prime = a.compose(&b_prime).unwrap();
//! let ba_prime = b.compose(&a_prime).unwrap();
//! let after_ab_prime = ab_prime.apply(s).unwrap();
//! let after_ba_prime = ba_prime.apply(s).unwrap();
//! assert_eq!(ab_prime, ba_prime);
//! assert_eq!(after_ab_prime, after_ba_prime);
//! ```
//!
//! ... invert sequences of operations
//! ```rust
//! use operational_transform::OperationSeq;
//!
//! let s = "abc";
//! let mut o = OperationSeq::default();
//! o.retain(3);
//! o.insert(&convert_utf16!("def"));
//! let p = o.invert(s);
//! assert_eq!(p.apply(&o.apply(s).unwrap()).unwrap(), s);
//! ```
//!
//! ## Features
//!
//! Serialisation is supporeted by using the `serde` feature.
//!
//! - Delete(n) will be serialized to -n
//! - Insert(s) will be serialized to "{s}"
//! - Retain(n) will be serailized to n
//!
//! ```rust,ignore
//! use operational_transform::OperationSeq;
//! use serde_json;
//!
//! let o: OperationSeq = serde_json::from_str("[1,-1,\"abc\"]").unwrap();
//! let mut o_exp = OperationSeq::default();
//! o_exp.retain(1);
//! o_exp.delete(1);
//! o_exp.insert("abc");
//! assert_eq!(o, o_exp);
//! ```
//!
//! ## Acknowledgement
//! In the current state the code is ported from
//! [here](https://github.com/Operational-Transformation/ot.js/). It might
//! change in the future as there is much room for optimisation and also
//! usability.

pub mod serde;

#[cfg(any(test, bench))]
pub mod utilities;

use std::{cmp::Ordering, error::Error, fmt, iter::FromIterator};

/// A single operation to be executed at the cursor's current position.
#[derive(Debug, Clone, PartialEq)]
pub enum Operation {
  // Deletes n characters at the current cursor position.
  Delete(u64),
  // Moves the cursor n positions forward.
  Retain(u64),
  // Inserts string at the current cursor position.
  Insert(Vec<u16>),
}

/// A sequence of `Operation`s on text.
#[derive(Clone, Debug, PartialEq)]
pub struct OperationSeq {
  // The consecutive operations to be applied to the target.
  ops: Vec<Operation>,
  // The required length of a string these operations can be applied to.
  base_len: usize,
  // The length of the resulting string after the operations have been
  // applied.
  target_len: usize,
}

impl Default for OperationSeq {
  fn default() -> Self {
    Self {
      ops: Vec::new(),
      base_len: 0,
      target_len: 0,
    }
  }
}

impl FromIterator<Operation> for OperationSeq {
  fn from_iter<T: IntoIterator<Item = Operation>>(ops: T) -> Self {
    let mut operations = OperationSeq::default();
    for op in ops {
      operations.add(op);
    }
    operations
  }
}

impl fmt::Display for OTError {
  fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    match self {
      OTError::BaseLengtMismatch(base_a, base_b) => write!(
        f,
        "Both operations have to have the same base length, base a: {}, base b: {}",
        base_a, base_b
      ),
      OTError::TargetBaseLengthMismatch(base, target) => write!(
        f,
        "Target and base length mismatch, base: {}, target: {}",
        base, target
      ),
      OTError::ComposeFirstOperationTooShort => write!(
        f,
        "Cannot compose operations: first operation is too short.",
      ),
      OTError::ComposeFirstOperationTooLong => {
        write!(f, "Cannot compose operations: first operation is too long.",)
      },
      OTError::OperationApplyMismatch(str_length, base_length) => write!(
        f,
        "The operation's base length must be equal to the string's length. String length: {}, base length: {}",
        str_length, base_length
      ),
    }
  }
}

impl Error for OTError {
  fn source(&self) -> Option<&(dyn Error + 'static)> {
    None
  }
}

#[derive(Clone, Debug)]
pub enum OTError {
  BaseLengtMismatch(usize, usize),
  TargetBaseLengthMismatch(usize, usize),
  ComposeFirstOperationTooShort,
  ComposeFirstOperationTooLong,
  OperationApplyMismatch(usize, usize),
}

impl OperationSeq {
  /// Merges the operation with `other` into one operation while preserving
  /// the changes of both. Or, in other words, for each input string S and a
  /// pair of consecutive operations A and B.
  ///     `apply(apply(S, A), B) = apply(S, compose(A, B))`
  /// must hold.
  ///
  /// # Error
  ///
  /// Returns an `OTError` if the operations are not composable due to length
  /// conflicts.
  pub fn compose(&self, other: &Self) -> Result<Self, OTError> {
    if self.target_len != other.base_len {
      return Err(OTError::TargetBaseLengthMismatch(
        other.base_len,
        self.target_len,
      ));
    }

    let mut new_op_seq = OperationSeq::default();
    let mut ops1 = self.ops.iter().cloned();
    let mut ops2 = other.ops.iter().cloned();

    let mut maybe_op1 = ops1.next();
    let mut maybe_op2 = ops2.next();
    loop {
      match (&maybe_op1, &maybe_op2) {
        (None, None) => break,
        (Some(Operation::Delete(i)), _) => {
          new_op_seq.delete(*i);
          maybe_op1 = ops1.next();
        }
        (_, Some(Operation::Insert(s))) => {
          new_op_seq.insert(&s);
          maybe_op2 = ops2.next();
        }
        (None, _) => {
          return Err(OTError::ComposeFirstOperationTooShort);
        }
        (_, None) => {
          return Err(OTError::ComposeFirstOperationTooLong);
        }
        (Some(Operation::Retain(i)), Some(Operation::Retain(j))) => match i.cmp(&j) {
          Ordering::Less => {
            new_op_seq.retain(*i);
            maybe_op2 = Some(Operation::Retain(*j - *i));
            maybe_op1 = ops1.next();
          }
          std::cmp::Ordering::Equal => {
            new_op_seq.retain(*i);
            maybe_op1 = ops1.next();
            maybe_op2 = ops2.next();
          }
          std::cmp::Ordering::Greater => {
            new_op_seq.retain(*j);
            maybe_op1 = Some(Operation::Retain(*i - *j));
            maybe_op2 = ops2.next();
          }
        },
        (Some(Operation::Insert(s)), Some(Operation::Delete(j))) => match (s.len() as u64).cmp(j) {
          Ordering::Less => {
            maybe_op2 = Some(Operation::Delete(*j - s.len() as u64));
            maybe_op1 = ops1.next();
          }
          Ordering::Equal => {
            maybe_op1 = ops1.next();
            maybe_op2 = ops2.next();
          }
          Ordering::Greater => {
            let iter = s.iter().cloned();
            maybe_op1 = Some(Operation::Insert(iter.skip(*j as usize).collect()));
            maybe_op2 = ops2.next();
          }
        },
        (Some(Operation::Insert(s)), Some(Operation::Retain(j))) => match (s.len() as u64).cmp(j) {
          Ordering::Less => {
            new_op_seq.insert(&s);
            maybe_op2 = Some(Operation::Retain(*j - s.len() as u64));
            maybe_op1 = ops1.next();
          }
          Ordering::Equal => {
            new_op_seq.insert(&s);
            maybe_op1 = ops1.next();
            maybe_op2 = ops2.next();
          }
          Ordering::Greater => {
            let chars = &mut s.iter().cloned();
            new_op_seq.insert(&chars.take(*j as usize).collect::<Vec<u16>>());
            maybe_op1 = Some(Operation::Insert(chars.collect()));
            maybe_op2 = ops2.next();
          }
        },
        (Some(Operation::Retain(i)), Some(Operation::Delete(j))) => match i.cmp(&j) {
          Ordering::Less => {
            new_op_seq.delete(*i);
            maybe_op2 = Some(Operation::Delete(*j - *i));
            maybe_op1 = ops1.next();
          }
          Ordering::Equal => {
            new_op_seq.delete(*j);
            maybe_op2 = ops2.next();
            maybe_op1 = ops1.next();
          }
          Ordering::Greater => {
            new_op_seq.delete(*j);
            maybe_op1 = Some(Operation::Retain(*i - *j));
            maybe_op2 = ops2.next();
          }
        },
      };
    }
    Ok(new_op_seq)
  }

  fn add(&mut self, op: Operation) {
    match op {
      Operation::Delete(i) => self.delete(i),
      Operation::Insert(s) => self.insert(&s),
      Operation::Retain(i) => self.retain(i),
    }
  }

  /// Deletes `n` characters at the current cursor position.
  pub fn delete(&mut self, n: u64) {
    if n == 0 {
      return;
    }
    self.base_len += n as usize;
    if let Some(Operation::Delete(n_last)) = self.ops.last_mut() {
      *n_last += n;
    } else {
      self.ops.push(Operation::Delete(n));
    }
  }

  /// Inserts a `s` at the current cursor position.
  pub fn insert(&mut self, s: &Vec<u16>) {
    if s.is_empty() {
      return;
    }
    self.target_len += s.len();
    let new_last = match self.ops.as_mut_slice() {
      [.., Operation::Insert(s_last)] => {
        &s_last.extend(s);
        return;
      }
      [.., Operation::Insert(s_pre_last), Operation::Delete(_)] => {
        &s_pre_last.extend(s);
        return;
      }
      [.., op_last @ Operation::Delete(_)] => {
        let new_last = op_last.clone();
        *op_last = Operation::Insert(s.to_owned());
        new_last
      }
      _ => Operation::Insert(s.to_owned()),
    };
    self.ops.push(new_last);
  }

  /// Moves the cursor `n` characters forwards.
  pub fn retain(&mut self, n: u64) {
    if n == 0 {
      return;
    }
    self.base_len += n as usize;
    self.target_len += n as usize;
    if let Some(Operation::Retain(i_last)) = self.ops.last_mut() {
      *i_last += n;
    } else {
      self.ops.push(Operation::Retain(n));
    }
  }

  /// Transforms two operations A and B that happened concurrently and produces
  /// two operations A' and B' (in an array) such that
  ///     `apply(apply(S, A), B') = apply(apply(S, B), A')`.
  /// This function is the heart of OT.
  ///
  /// # Error
  ///
  /// Returns an `OTError` if the operations cannot be transformed due to
  /// length conflicts.
  pub fn transform(&self, other: &Self) -> Result<(Self, Self), OTError> {
    if self.base_len != other.base_len {
      return Err(OTError::BaseLengtMismatch(self.base_len, other.base_len));
    }

    let mut a_prime = OperationSeq::default();
    let mut b_prime = OperationSeq::default();

    let mut ops1 = self.ops.iter().cloned();
    let mut ops2 = other.ops.iter().cloned();

    let mut maybe_op1 = ops1.next();
    let mut maybe_op2 = ops2.next();
    loop {
      match (&maybe_op1, &maybe_op2) {
        (None, None) => break,
        (Some(Operation::Insert(s)), _) => {
          a_prime.insert(s);
          b_prime.retain(s.len() as _);
          maybe_op1 = ops1.next();
        }
        (_, Some(Operation::Insert(s))) => {
          a_prime.retain(s.len() as _);
          b_prime.insert(s);
          maybe_op2 = ops2.next();
        }
        (None, _) => {
          return Err(OTError::ComposeFirstOperationTooShort {});
        }
        (_, None) => {
          return Err(OTError::ComposeFirstOperationTooLong {});
        }
        (Some(Operation::Retain(i)), Some(Operation::Retain(j))) => {
          let min;
          match i.cmp(&j) {
            Ordering::Less => {
              min = *i;
              maybe_op2 = Some(Operation::Retain(*j - *i));
              maybe_op1 = ops1.next();
            }
            Ordering::Equal => {
              min = *j;
              maybe_op1 = ops1.next();
              maybe_op2 = ops2.next();
            }
            Ordering::Greater => {
              min = *j;
              maybe_op1 = Some(Operation::Retain(*i - *j));
              maybe_op2 = ops2.next();
            }
          };
          a_prime.retain(min);
          b_prime.retain(min);
        }
        (Some(Operation::Delete(i)), Some(Operation::Delete(j))) => match i.cmp(&j) {
          Ordering::Less => {
            maybe_op2 = Some(Operation::Delete(*j - *i));
            maybe_op1 = ops1.next();
          }
          Ordering::Equal => {
            maybe_op1 = ops1.next();
            maybe_op2 = ops2.next();
          }
          Ordering::Greater => {
            maybe_op1 = Some(Operation::Delete(*i - *j));
            maybe_op2 = ops2.next();
          }
        },
        (Some(Operation::Delete(i)), Some(Operation::Retain(j))) => {
          let min;
          match i.cmp(&j) {
            Ordering::Less => {
              min = *i;
              maybe_op2 = Some(Operation::Retain(*j - *i));
              maybe_op1 = ops1.next();
            }
            Ordering::Equal => {
              min = *i;
              maybe_op1 = ops1.next();
              maybe_op2 = ops2.next();
            }
            Ordering::Greater => {
              min = *j;
              maybe_op1 = Some(Operation::Delete(*i - *j));
              maybe_op2 = ops2.next();
            }
          };
          a_prime.delete(min);
        }
        (Some(Operation::Retain(i)), Some(Operation::Delete(j))) => {
          let min;
          match i.cmp(&j) {
            Ordering::Less => {
              min = *i;
              maybe_op2 = Some(Operation::Delete(*j - *i));
              maybe_op1 = ops1.next();
            }
            Ordering::Equal => {
              min = *i;
              maybe_op1 = ops1.next();
              maybe_op2 = ops2.next();
            }
            Ordering::Greater => {
              min = *j;
              maybe_op1 = Some(Operation::Retain(*i - *j));
              maybe_op2 = ops2.next();
            }
          };
          b_prime.delete(min);
        }
      }
    }

    Ok((a_prime, b_prime))
  }

  /// Applies an operation to a string, returning a new string.
  ///
  /// # Error
  ///
  /// Returns an error if the operation cannot be applied due to length
  /// conflicts.
  pub fn apply(&self, s: &Vec<u16>) -> Result<Vec<u16>, OTError> {
    let str_length = s.len();
    if str_length != self.base_len {
      return Err(OTError::OperationApplyMismatch(str_length, self.base_len));
    }
    let mut new_s: Vec<u16> = Vec::new();
    let chars = &mut s.iter();
    for op in self.ops.iter() {
      match op {
        Operation::Retain(retain) => {
          for c in chars.take(*retain as usize) {
            new_s.push(*c);
          }
        }
        Operation::Delete(delete) => {
          for _ in 0..*delete {
            chars.next();
          }
        }
        Operation::Insert(insert) => {
          new_s.extend(insert);
        }
      }
    }

    Ok(new_s)
  }

  /// Computes the inverse of an operation. The inverse of an operation is the
  /// operation that reverts the effects of the operation, e.g. when you have
  /// an operation 'insert("hello "); skip(6);' then the inverse is
  /// 'delete("hello "); skip(6);'. The inverse should be used for
  /// implementing undo.
  pub fn invert(&self, s: &Vec<u16>) -> Self {
    let mut inverse = OperationSeq::default();
    let chars = &mut s.iter().cloned();
    for op in self.ops.iter() {
      match op {
        Operation::Retain(retain) => {
          inverse.retain(*retain);
          for _ in 0..*retain {
            chars.next();
          }
        }
        Operation::Insert(insert) => {
          inverse.delete(insert.len() as u64);
        }
        Operation::Delete(delete) => {
          inverse.insert(&chars.take(*delete as usize).collect::<Vec<u16>>());
        }
      }
    }
    inverse
  }

  /// Checks if this operation has no effect.
  pub fn is_noop(&self) -> bool {
    match self.ops.as_slice() {
      [] => true,
      [Operation::Retain(_)] => true,
      _ => false,
    }
  }

  /// Returns the length of a string these operations can be applied to
  pub fn base_len(&self) -> usize {
    self.base_len
  }

  /// Returns the length of the resulting string after the operations have
  /// been applied.
  pub fn target_len(&self) -> usize {
    self.target_len
  }

  /// Returns the wrapped sequence of operations.
  pub fn ops(&self) -> &Vec<Operation> {
    &self.ops
  }
}

#[cfg(test)]
mod tests {
  use super::utilities::Rng;
  use super::*;

  macro_rules! convert_utf16 {
    ($e:expr) => {
      $e.encode_utf16().collect();
    };
  }

  #[test]
  fn lengths() {
    let mut o = OperationSeq::default();
    assert_eq!(o.base_len, 0);
    assert_eq!(o.target_len, 0);
    o.retain(5);
    assert_eq!(o.base_len, 5);
    assert_eq!(o.target_len, 5);
    o.insert(&convert_utf16!("abc"));
    assert_eq!(o.base_len, 5);
    assert_eq!(o.target_len, 8);
    o.retain(2);
    assert_eq!(o.base_len, 7);
    assert_eq!(o.target_len, 10);
    o.delete(2);
    assert_eq!(o.base_len, 9);
    assert_eq!(o.target_len, 10);
  }

  #[test]
  fn sequence() {
    let mut o = OperationSeq::default();
    o.retain(5);
    o.retain(0);
    o.insert(&convert_utf16!("lorem"));
    o.insert(&convert_utf16!(""));
    o.delete(3);
    o.delete(0);
    assert_eq!(o.ops.len(), 3);
  }

  #[test]
  fn apply() {
    for _ in 0..1000 {
      let mut rng = Rng::default();
      let s = rng.gen_string(50);
      let o = rng.gen_operation_seq(&s);
      assert_eq!(s.len(), o.base_len);
      assert_eq!(o.apply(&s).unwrap().len(), o.target_len);
    }
  }

  #[test]
  fn invert() {
    for _ in 0..1000 {
      let mut rng = Rng::default();
      let s = rng.gen_string(50);
      let o = rng.gen_operation_seq(&s);
      let p = o.invert(&s);
      assert_eq!(o.base_len, p.target_len);
      assert_eq!(o.target_len, p.base_len);
      assert_eq!(p.apply(&o.apply(&s).unwrap()).unwrap(), s);
    }
  }

  #[test]
  fn empty_ops() {
    let mut o = OperationSeq::default();
    o.retain(0);
    o.insert(&convert_utf16!(""));
    o.delete(0);
    assert_eq!(o.ops.len(), 0);
  }

  #[test]
  fn eq() {
    let mut o1 = OperationSeq::default();
    o1.delete(1);
    o1.insert(&convert_utf16!("lo"));
    o1.retain(2);
    o1.retain(3);
    let mut o2 = OperationSeq::default();
    o2.delete(1);
    o2.insert(&convert_utf16!("l"));
    o2.insert(&convert_utf16!("o"));
    o2.retain(5);
    assert_eq!(o1, o2);
    o1.delete(1);
    o2.retain(1);
    assert_ne!(o1, o2);
  }

  #[test]
  fn ops_merging() {
    let mut o = OperationSeq::default();
    assert_eq!(o.ops.len(), 0);
    o.retain(2);
    assert_eq!(o.ops.len(), 1);
    assert_eq!(o.ops.last(), Some(&Operation::Retain(2)));
    o.retain(3);
    assert_eq!(o.ops.len(), 1);
    assert_eq!(o.ops.last(), Some(&Operation::Retain(5)));
    o.insert(&convert_utf16!("abc"));
    assert_eq!(o.ops.len(), 2);
    assert_eq!(
      o.ops.last(),
      Some(&Operation::Insert(convert_utf16!("abc")))
    );
    o.insert(&convert_utf16!("xyz"));
    assert_eq!(o.ops.len(), 2);
    assert_eq!(
      o.ops.last(),
      Some(&Operation::Insert(convert_utf16!("abcxyz")))
    );
    o.delete(1);
    assert_eq!(o.ops.len(), 3);
    assert_eq!(o.ops.last(), Some(&Operation::Delete(1)));
    o.delete(1);
    assert_eq!(o.ops.len(), 3);
    assert_eq!(o.ops.last(), Some(&Operation::Delete(2)));
  }

  #[test]
  fn is_noop() {
    let mut o = OperationSeq::default();
    assert!(o.is_noop());
    o.retain(5);
    assert!(o.is_noop());
    o.retain(3);
    assert!(o.is_noop());
    o.insert(&convert_utf16!("lorem"));
    assert!(!o.is_noop());
  }

  #[test]
  fn compose() {
    for _ in 0..1000 {
      let mut rng = Rng::default();
      let s = rng.gen_string(20);
      let a = rng.gen_operation_seq(&s);
      let after_a = a.apply(&s).unwrap();
      assert_eq!(a.target_len, after_a.len());
      let b = rng.gen_operation_seq(&after_a);
      let after_b = b.apply(&after_a).unwrap();
      assert_eq!(b.target_len, after_b.len());
      let ab = a.compose(&b).unwrap();
      assert_eq!(ab.target_len, b.target_len);
      let after_ab = ab.apply(&s).unwrap();
      assert_eq!(after_b, after_ab);
    }
  }

  #[test]
  fn transform() {
    for _ in 0..1000 {
      let mut rng = Rng::default();
      let s = rng.gen_string(20);
      let a = rng.gen_operation_seq(&s);
      let b = rng.gen_operation_seq(&s);
      let (a_prime, b_prime) = a.transform(&b).unwrap();
      let ab_prime = a.compose(&b_prime).unwrap();
      let ba_prime = b.compose(&a_prime).unwrap();
      let after_ab_prime = ab_prime.apply(&s).unwrap();
      let after_ba_prime = ba_prime.apply(&s).unwrap();
      assert_eq!(ab_prime, ba_prime);
      assert_eq!(after_ab_prime, after_ba_prime);
    }
  }

  #[test]
  #[cfg(feature = "serde")]
  fn serde() {
    use serde_json;

    let mut rng = Rng::default();

    let o: OperationSeq = serde_json::from_str("[1,-1,\"abc\"]").unwrap();
    let mut o_exp = OperationSeq::default();
    o_exp.retain(1);
    o_exp.delete(1);
    o_exp.insert("abc");
    assert_eq!(o, o_exp);
    for _ in 0..1000 {
      let s = rng.gen_string(20);
      let o = rng.gen_operation_seq(&s);
      assert_eq!(
        o,
        serde_json::from_str(&serde_json::to_string(&o).unwrap()).unwrap()
      );
    }
  }
}
