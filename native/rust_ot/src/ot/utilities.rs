use crate::OperationSeq;
use rand::prelude::*;
use rand::Rng as WrappedRng;

pub struct Rng(StdRng);

impl Default for Rng {
  fn default() -> Self {
    Rng(StdRng::from_rng(thread_rng()).unwrap())
  }
}

impl Rng {
  pub fn from_seed(seed: [u8; 32]) -> Self {
    Rng(StdRng::from_seed(seed))
  }

  pub fn gen_string(&mut self, len: usize) -> Vec<u16> {
    (0..len)
      .map(|_| self.0.gen::<char>())
      .collect::<String>()
      .encode_utf16()
      .collect()
  }

  pub fn gen_operation_seq(&mut self, s: &Vec<u16>) -> OperationSeq {
    let mut op = OperationSeq::default();
    loop {
      let left = s.len() - op.base_len();
      if left == 0 {
        break;
      }
      let i = if left == 1 {
        1
      } else {
        1 + self.0.gen_range(0, std::cmp::min(left - 1, 20))
      };
      match self.0.gen_range(0.0, 1.0) {
        f if f < 0.2 => {
          op.insert(&self.gen_string(i));
        }
        f if f < 0.4 => {
          op.delete(i as u64);
        }
        _ => {
          op.retain(i as u64);
        }
      }
    }
    if self.0.gen_range(0.0, 1.0) < 0.3 {
      let mut base: Vec<u16> = "1".encode_utf16().collect();
      base.extend(self.gen_string(10));

      op.insert(&base);
    }
    op
  }
}
