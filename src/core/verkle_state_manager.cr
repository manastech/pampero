require "../models/account"
require "../models/verkle_execution_witness"
require "../common/address"
require "../common/types"
require "../core/verkle_crypto"
require "../core/verkle_state"

module Pampero
  LEAF_VERSION   = 0u8
  LEAF_BALANCE   = 1u8
  LEAF_NONCE     = 2u8
  LEAF_CODE_HASH = 3u8
  LEAF_CODE_SIZE = 4u8

  class VerkleStateManager
    def initialize
      @state = VerkleState.new
    end

    def init_execution_witness(execution_witness : VerkleExecutionWitness)
      @state.init_execution_witness execution_witness
    end

    def get_account(address : Address20) : Account?
      stem = get_stem address, 0_u64

      result = read_account(stem)

      if (version = result[:version]).nil? ||
        (balance = result[:balance]).nil? ||
        (nonce = result[:nonce]).nil? ||
        (code_hash = result[:code_hash]).nil? ||
        (code_size = result[:code_size]).nil?
        return nil
      end

      account = Account.new
      account.version = version
      account.balance = balance
      account.nonce = nonce
      account.code_hash = code_hash
      account.code_size = code_size

      account
    end

    # The stem are first 31 bytes
    def get_stem(address : Address20, treeIndex : UInt64) : Bytes32
      address32 = Address32.new 0_u8

      20.times do |i|
        address32[12 + i] = address.@data[i]
      end

      index = Bytes32.new treeIndex

      get_tree_key address32, index, 0_u8
    end

    def read_account(stem : Bytes32)
      {
        version: read_version(stem),
        balance: read_balance(stem),
        nonce: read_nonce(stem),
        code_hash: read_code_hash(stem),
        code_size: read_code_size(stem)
      }
    end

    def get_tree_key(address : Address32, treeIndex : Bytes32, subIndex : UInt8) : Bytes32
      data = Bytes64.new address, treeIndex.@data
      key = Pampero::Crypto.hash data
      key.@data[31] = subIndex
      key
    end

    def read_version(stem : Bytes32) : UInt256?
      key = get_key stem, LEAF_VERSION
      if result = read_key(key)
        result = result.to_uint256
      end
      result
    end

    def read_balance(stem : Bytes32) : UInt256?
      key = get_key stem, LEAF_BALANCE
      if result = read_key(key)
        result = result.to_uint256
      end
      result
    end

    def read_nonce(stem : Bytes32) : UInt256?
      key = get_key stem, LEAF_NONCE
      if result = read_key(key)
        result = result.to_uint256
      end
      result
    end

    def read_code_hash(stem : Bytes32) : Bytes32?
      key = get_key stem, LEAF_CODE_HASH
      read_key(key)
    end

    def read_code_size(stem : Bytes32) : UInt256?
      key = get_key stem, LEAF_CODE_SIZE
      if result = read_key(key)
        result = result.to_uint256
      end
      result
    end

    def get_key(stem : Bytes32, leaf : UInt8) : Bytes32
      key = Bytes32.new stem.@data
      key.@data[31] = leaf
      key
    end

    def read_key(key : Bytes32) : Bytes32?
      @state.read_key key
    end
  end
end
