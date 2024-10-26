

# Define a class for bank accounts
class BankAccount:
    def __init__(self, account_number: str, balance: float):
        self.account_number: str = account_number
        self.balance: float = balance
    
    # Method for depositing money into the account
    def deposit(self, amount: float) -> None:
        self.balance += amount
        print(f"Deposited ${amount}. New balance: ${self.balance}")
    
    # Method for withdrawing money from the account
    def withdraw(self, amount: float) -> None:
        if self.balance >= amount:
            self.balance -= amount
            print(f"Withdrew ${amount}. New balance: ${self.balance}")
        else:
            print("Insufficient funds!")
    
    # Method to display account information
    def display(self) -> None:
        print(f"Account Number: {self.account_number}, Balance: ${self.balance}")

# Define a subclass for savings accounts
class SavingsAccount(BankAccount):
    def __init__(self, account_number: str, balance: float, interest_rate: float):
        self.account_number = account_number
        self.balance = balance
        self.interest_rate: float = interest_rate
    
    # Method to calculate and add interest to the balance
    def add_interest(self) -> None:
        interest_amount: float = self.balance * (self.interest_rate / 100)
        self.balance += interest_amount
        print(f"Interest added: ${interest_amount}. New balance: ${self.balance}")

# Define a subclass for checking accounts
class CheckingAccount(BankAccount):
    def __init__(self, account_number: str, balance: float, overdraft_limit: float):
        self.account_number = account_number
        self.balance = balance
        self.overdraft_limit: float = overdraft_limit
    
    # Method to withdraw money, allowing overdraft up to the limit
    def withdraw(self, amount: float) -> None:
        if self.balance + self.overdraft_limit >= amount:
            self.balance -= amount
            print(f"Withdrew ${amount}. New balance: ${self.balance}")
        else:
            print("Transaction declined! Overdraft limit exceeded.")

def main() -> None:
    # Create a savings account
    savings_acc :SavingsAccount= SavingsAccount("SA001", 1000, 2.5)
    savings_acc.deposit(500)
    savings_acc.add_interest()
    savings_acc.withdraw(200)
    savings_acc.display()

    print("--------------------------------")

    # Create a checking account
    checking_acc :CheckingAccount= CheckingAccount("CA001", 2000, 500)
    checking_acc.deposit(1000)
    checking_acc.withdraw(3000)
    checking_acc.withdraw(500)
    checking_acc.display()

if __name__ == "__main__":
    main()
