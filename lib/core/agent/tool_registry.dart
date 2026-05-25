class ToolRegistry {
  static List<Map<String, dynamic>> getAllToolDefinitions() {
    return [
      {
        'type': 'function',
        'function': {
          'name': 'create_transaction',
          'description': 'Record a new income or expense transaction',
          'parameters': {
            'type': 'object',
            'properties': {
              'amount': {'type': 'number', 'description': 'Transaction amount'},
              'category': {'type': 'string', 'description': 'Category name, e.g. 餐饮/交通/购物'},
              'account': {'type': 'string', 'description': 'Account name, e.g. 微信/支付宝/银行卡. Use default if not specified'},
              'type': {'type': 'string', 'enum': ['income', 'expense'], 'description': 'Income or expense'},
              'note': {'type': 'string', 'description': 'Optional note'},
              'date': {'type': 'string', 'description': 'Date in YYYY-MM-DD format. Use today if not specified'},
            },
            'required': ['amount', 'category', 'type'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'update_transaction',
          'description': 'Update an existing transaction',
          'parameters': {
            'type': 'object',
            'properties': {
              'id': {'type': 'integer', 'description': 'Transaction ID to update'},
              'amount': {'type': 'number', 'description': 'New amount'},
              'category': {'type': 'string', 'description': 'New category'},
              'note': {'type': 'string', 'description': 'New note'},
              'account': {'type': 'string', 'description': 'New account'},
            },
            'required': ['id'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'delete_transaction',
          'description': 'Delete a transaction by ID',
          'parameters': {
            'type': 'object',
            'properties': {
              'id': {'type': 'integer', 'description': 'Transaction ID to delete'},
            },
            'required': ['id'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'query_transactions',
          'description': 'Query transaction history',
          'parameters': {
            'type': 'object',
            'properties': {
              'date_from': {'type': 'string', 'description': 'Start date YYYY-MM-DD'},
              'date_to': {'type': 'string', 'description': 'End date YYYY-MM-DD'},
              'category': {'type': 'string', 'description': 'Filter by category'},
              'limit': {'type': 'integer', 'description': 'Max results, default 20'},
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'create_transfer',
          'description': 'Transfer money between accounts',
          'parameters': {
            'type': 'object',
            'properties': {
              'from_account': {'type': 'string', 'description': 'Source account name'},
              'to_account': {'type': 'string', 'description': 'Destination account name'},
              'amount': {'type': 'number', 'description': 'Transfer amount'},
              'note': {'type': 'string', 'description': 'Optional note'},
            },
            'required': ['from_account', 'to_account', 'amount'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'check_budget',
          'description': 'Check budget usage for a category or overall',
          'parameters': {
            'type': 'object',
            'properties': {
              'category': {'type': 'string', 'description': 'Category to check, omit for overall budget'},
              'month': {'type': 'string', 'description': 'Month in YYYY-MM format'},
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'query_balance',
          'description': 'Query account balance',
          'parameters': {
            'type': 'object',
            'properties': {
              'account': {'type': 'string', 'description': 'Account name, omit for all accounts'},
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'query_assets',
          'description': 'Get total assets overview: assets, liabilities, net assets',
          'parameters': {'type': 'object', 'properties': {}},
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'update_profile',
          'description': 'Update user profile information',
          'parameters': {
            'type': 'object',
            'properties': {
              'key': {'type': 'string', 'description': 'Profile key, e.g. name, salary, payment_habit'},
              'value': {'type': 'string', 'description': 'Profile value'},
            },
            'required': ['key', 'value'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'save_episodic',
          'description': 'Save an important event to episodic memory',
          'parameters': {
            'type': 'object',
            'properties': {
              'event': {'type': 'string', 'description': 'Event description'},
              'date': {'type': 'string', 'description': 'Event date YYYY-MM-DD'},
              'tags': {'type': 'string', 'description': 'Comma-separated tags'},
              'importance': {'type': 'integer', 'description': 'Importance 1-5, default 3'},
            },
            'required': ['event'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'compact',
          'description': 'Manually trigger context compression to save tokens',
          'parameters': {'type': 'object', 'properties': {}},
        },
      },
    ];
  }
}
