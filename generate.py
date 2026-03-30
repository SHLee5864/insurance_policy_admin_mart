import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
import names

np.random.seed(42)
random.seed(42)

# -----------------------------
# 1) Product Table
# -----------------------------
products = []
product_ids = [f"PRD{i:02d}" for i in range(1, 11)]
product_names = [
    "Life Basic", "Life Plus", "Accident Basic", "Accident Premium",
    "Health Basic", "Health Plus", "Cancer Basic", "Cancer Premium",
    "Disability Basic", "Disability Premium"
]

for pid, pname in zip(product_ids, product_names):
    products.append([pid, pname, "Y"])

df_product = pd.DataFrame(products, columns=["product_id", "product_name", "renewal_flag"])


# -----------------------------
# 2) Generate Insureds
# -----------------------------
def random_birthdate():
    start = datetime(1950, 1, 1)
    end = datetime(2005, 12, 31)
    delta = end - start
    return start + timedelta(days=random.randint(0, delta.days))

regions = ["Paris", "Lyon", "Marseille", "Lille", "Bordeaux", "Nice", "Toulouse"]

insureds = []
insured_counter = 1

def create_insured():
    global insured_counter
    iid = f"I{insured_counter:05d}"
    insured_counter += 1
    gender = random.choice(["M", "F"])
    name = names.get_full_name(gender=("male" if gender=="M" else "female"))
    birth = random_birthdate().date()
    region = random.choice(regions)
    return [iid, name, gender, birth, region]


# -----------------------------
# 3) Policies + Status History
# -----------------------------
start_date = datetime(2023, 1, 1)
end_date = datetime(2025, 12, 31)

months = pd.date_range(start_date, end_date, freq="MS")

policies = []
status_history = []
coverages = []
premiums = []
claims = []

policy_counter = 1

# coverage templates per product
coverage_templates = {
    pid: [f"COV{i:02d}" for i in range(1, random.randint(5, 10))]
    for pid in product_ids
}

active_policies = {}  # policy_id → product_id

for month in months:
    # target active count
    target_active = random.randint(30, 50)

    # 1) Remove some active policies (expiry or cancellation)
    to_remove = max(0, len(active_policies) - target_active)
    remove_ids = random.sample(list(active_policies.keys()), to_remove) if to_remove > 0 else []

    for rid in remove_ids:
        # cancellation
        status_history.append([rid, "cancelled", month.date(), None, month.date()])
        del active_policies[rid]

    # 2) Add new policies to reach target
    to_add = target_active - len(active_policies)
    for _ in range(to_add):
        pid = f"P{policy_counter:05d}"
        policy_counter += 1

        insured = create_insured()
        insureds.append(insured)

        product_id = random.choice(product_ids)
        eff_date = month + timedelta(days=random.randint(0, 27))
        exp_date = eff_date + timedelta(days=365)

        policies.append([pid, insured[0], product_id, "active", eff_date.date(), exp_date.date(), eff_date.date()])

        # status history initial
        status_history.append([pid, "active", eff_date.date(), None, eff_date.date()])

        active_policies[pid] = product_id

        # coverages
        for cov in coverage_templates[product_id]:
            limit = random.randint(10000, 200000)
            deductible = random.choice([0, 50, 100, 200, 500])
            coverages.append([pid, cov, cov, limit, deductible])

    # 3) Premiums for active policies
    for pid in active_policies.keys():
        premium_amount = random.randint(30, 200)
        pay_date = month + timedelta(days=random.randint(0, 27))
        premium_id = f"PMT{len(premiums)+1:07d}"
        premiums.append([premium_id, pid, premium_amount, pay_date.date(), random.choice(["card", "bank"])])


# -----------------------------
# 4) Claims (loss ratio 85~105%)
# -----------------------------
df_premium = pd.DataFrame(premiums, columns=["premium_id", "policy_id", "amount", "payment_date", "payment_method"])
df_premium["year"] = pd.to_datetime(df_premium["payment_date"]).dt.year

df_claims = []

for year in [2023, 2024, 2025]:
    for pid in product_ids:
        # total premium for this product-year
        pols = [p[0] for p in policies if p[2] == pid]
        total_prem = df_premium[(df_premium["policy_id"].isin(pols)) & (df_premium["year"] == year)]["amount"].sum()

        if total_prem == 0:
            continue

        target_claims = total_prem * random.uniform(0.85, 1.05)

        # distribute claims
        remaining = target_claims
        while remaining > 0:
            claim_amount = min(random.randint(200, 5000), remaining)
            remaining -= claim_amount

            # pick random policy
            pol = random.choice(pols)
            claim_date = datetime(year, random.randint(1, 12), random.randint(1, 28))
            claim_id = f"CLM{len(df_claims)+1:07d}"

            df_claims.append([claim_id, pol, claim_amount, claim_date.date(), "general", "paid"])

df_claims = pd.DataFrame(df_claims, columns=["claim_id", "policy_id", "claim_amount", "claim_date", "claim_type", "status"])


# -----------------------------
# Save CSVs
# -----------------------------
pd.DataFrame(insureds, columns=["insured_id", "name", "gender", "birth_date", "region"]).to_csv("insureds.csv", index=False)
df_product.to_csv("product.csv", index=False)
pd.DataFrame(policies, columns=["policy_id", "insured_id", "product_id", "status", "effective_date", "expiry_date", "updated_at"]).to_csv("policies.csv", index=False)
pd.DataFrame(status_history, columns=["policy_id", "status", "start_date", "end_date", "updated_at"]).to_csv("policy_status_history.csv", index=False)
pd.DataFrame(coverages, columns=["policy_id", "coverage_id", "coverage_type", "limit", "deductible"]).to_csv("coverages.csv", index=False)
df_premium.to_csv("premium.csv", index=False)
df_claims.to_csv("claims.csv", index=False)

print("All CSVs generated!")
