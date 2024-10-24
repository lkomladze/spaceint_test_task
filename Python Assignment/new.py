import pandas as pd
from datetime import datetime
import json

# load csv
data = pd.read_csv('data.csv')

# variables
features = []
excluded_banks = ['LIZ', 'LOM', 'MKO', 'SUG', None]

# process dataset
for index, row in data.iterrows():
    try:
        application_date = datetime.strptime(row['application_date'], '%Y-%m-%d %H:%M:%S.%f%z').replace(tzinfo=None)
    except ValueError as e:
        continue  #tu ver vamushaveb vskipav

    claims = []
    loans = []

    if pd.isna(row['contracts']) or not isinstance(row['contracts'], str) or not row['contracts'].strip():
        continue 

    try:
        contracts = json.loads(row['contracts'])
    except json.JSONDecodeError:
        continue 

    if not isinstance(contracts, list):
        continue  

    for contract in contracts:
        if isinstance(contract, dict):
            if 'claim_date' in contract and contract['claim_date'].strip():
                try:
                    claim_date = datetime.strptime(contract['claim_date'], '%d.%m.%Y')
                    claims.append(claim_date)
                except ValueError as e:
                    continue 

            if 'loan_summa' in contract and 'contract_date' in contract:
                if contract['contract_date'].strip():
                    try:
                        loan_date = datetime.strptime(contract['contract_date'], '%d.%m.%Y')
                        loan_summa = contract['loan_summa']
                        bank = contract.get('bank') 
                        
                        if isinstance(loan_summa, str):
                            loan_summa = float(loan_summa)

                        if bank not in excluded_banks:
                            loans.append({'loan_date': loan_date, 'loan_summa': loan_summa})
                    except ValueError as e:
                        continue  

    # features
    # number of claims for last 180 days - tot_claim_cnt_l180d
    claims_last_180_days = [claim for claim in claims if (application_date - claim).days <= 180]
    tot_claim_cnt_l180d = len(claims_last_180_days) if claims_last_180_days else -3

    # sum of loan exposure excluding certain banks - disb_bank_loan_wo_tbc
    disb_bank_loan_wo_tbc = sum(loan['loan_summa'] for loan in loans) if loans else -1 

    # number of days since last loan. - day_sinlastloan
    if loans:
        last_loan = max(loan['loan_date'] for loan in loans)
        day_sinlastloan = (application_date - last_loan).days
    else:
        day_sinlastloan = -1  

    features.append({
        'id': row['id'],
        'application_date': application_date,
        'tot_claim_cnt_l180d': tot_claim_cnt_l180d,
        'disb_bank_loan_wo_tbc': disb_bank_loan_wo_tbc,
        'day_sinlastloan': day_sinlastloan,
    })

result_df = pd.DataFrame(features)
result_df.to_csv('contract_features.csv')

