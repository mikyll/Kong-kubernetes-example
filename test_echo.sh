#!/bin/bash

###############################################################################
# Test /echo
TEST_PATH="/echo"
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" | grep "HTTP/1.1 200 OK")
RETURN_CODE=$?
if [[ "$RETURN_CODE" == "0" ]]
then
  echo "[OK] ${TEST_PATH} (200)"
else
  echo "[FAIL] ${TEST_PATH} (200)"
fi

###############################################################################
# Test /echo-ratelimit
TEST_PATH="/echo-ratelimit"
for i in {1..10}
do
  RESULT=$(curl -s -i "http://localhost${TEST_PATH}" | grep "HTTP/1.1")
  RETURN_CODE=$?
done
if [[ "$RESULT" == "HTTP/1.1 429 Too Many Requests" ]]
then
  echo "[OK] ${TEST_PATH} (429)"
else
  echo "[FAIL] ${TEST_PATH} (429)"
fi

###############################################################################
# Test /echo-keyauth
TEST_PATH="/echo-keyauth"
KEY_AUTH="apikey:alex_api_key"
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" -H "$KEY_AUTH" | grep "HTTP/1.1")
RETURN_CODE=$?
if [[ "$RESULT" == "HTTP/1.1 200 OK" ]]
then
  echo "[OK] ${TEST_PATH} (200)"
else
  echo "[FAIL] ${TEST_PATH} (200)"
fi
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" | grep "HTTP/1.1")
RETURN_CODE=$?
if [[ "$RESULT" == "HTTP/1.1 401 Unauthorized" ]]
then
  echo "[OK] ${TEST_PATH} (401)"
else
  echo "[FAIL] ${TEST_PATH} (401)"
fi

###############################################################################
# Test /echo-basicauth
TEST_PATH="/echo-basicauth"
BASIC_AUTH="$(echo -n joe:password | base64)"
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" -H "Authorization: Basic ${BASIC_AUTH}" | grep "HTTP/1.1")
RETURN_CODE=$?
if [[ "$RESULT" == "HTTP/1.1 200 OK" ]]
then
  echo "[OK] ${TEST_PATH} (200)"
else
  echo "[FAIL] ${TEST_PATH} (200)"
fi
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" | grep "HTTP/1.1")
RETURN_CODE=$?
if [[ "$RESULT" == "HTTP/1.1 401 Unauthorized" ]]
then
  echo "[OK] ${TEST_PATH} (401)"
else
  echo "[FAIL] ${TEST_PATH} (401)"
fi

###############################################################################
# Test /echo-jwtauth
TEST_PATH="/echo-jwtauth"
ADMIN_JWT="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhZG1pbi1pc3N1ZXIifQ.di8D15Bzmyafu36vEb_qYk4q2zN821jgRRZXgXO847xFSHkSc35nfmSS5Db7pYSOZ_8rdS3LAlNLA7v4BA-JhZfB95WbGy_nlLXk2dqhoF5jzTmVgNVYRwwIgzYdhSZ3Ks8tiXj_rs-jyHG8K7YNp8moW-Oz5dxolA_a9wbY2cGCZj_defxDpsK_TpbHh_4heg9OLVMAlKp5frgnYlSoDD11TcmX7YhLleXHXmkVK2aeGWvK8ooh2OptBXyeg0M81oaTt47SnTMyMeXhM1DnTvEaaTquFjnA83U7luOB7Cs_xXnk80wTYaw6Ml9BU6fIu9R7mNTjupKFPOw8J7iWcPQNsYkqlJoLjv24xOknGRrPPSuW1DFVT5V2BKjliB72PgI4o91F9fqfn12pBVn-OHgcHSvUxTcGKTObzU3Gu1g5sMHsvgaeADA5_faTzMdMyO6nELnaLOBZwr8kfA-tYOHAid2JBqgRtd919oLvR-QTtGN4gQq1-UNe38vdXsvDClB4PU-qA000I8obJAG_vr5FBBOPbdk82zVGVJpeOjwlddl0OSzakwSzm3PhRrAnvetos6NEP5YISxJNwsWVF6Ng-LtnrOl3ONdiVBogqcq_AV8ssPqIUhm2pjOJOMdBQ3HwzlakWWiWLnI1g07aGDf60cUDVJrxPQMJ485MTNA"
USER_JWT="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ1c2VyLWlzc3VlciJ9.oKgeiPBow5GGcAN_ODRdON9Y4uKq8SxngbfikmomiG4XVI-IjTAslc0NWTvCiOyq7s1leL4kqeD8IeLvw0u2CnKUuSJigwiTRs2NXbpyNpmftnt00xUXC4xHzHI_Rk8_zUCmlCQsU_pb87gcxuKXb0VKuAsEIeTpeCAmwKNxrH67zxeoHPcKA4BCLN-CsIKZZ-ko4JKl_1_PlsuuCt76-5ljR_tb5h2oeZaUTrIENLqnlLRU-0hESow31ZgOHZ0ANDJ0pNm-IR1cBcM09aH2iDgdX3D_w8JqZLTVeLZNdWyQ91NYaD9_KteFqSP_5ru3a_O1pT9rqXP6mJh-J3q9wVH_DYZAtxMIAbY3u30sNF-1Cz_ulxtOlgRbvM9Sm9gMRmOS1C0zv6aXOjvLgE6cOQ0gwxYvvIJ-e9eb7bJiW2LPiZAVWQROOKjINEjlJFgUcpn9b-l83Xl_kq9Bhct_RQqPZZff5ZUfE3jUUrGQM05pa01VtX6iUX64IrqZCz3no0FPoz7nuOmBSmuwzYNI2w-N-WTXIG-wo-9oVooSXpJbr9fqTIuAm0IuwbFcdhN6eV6SehJkLKZChFUrlXmsRa0ZqarKiDYcSJLBx7pGQ789FcQmErh-QCiynfn2g0K8R0aJ7CGD3nmW1qoGsodnJ3uvR_-lLn1n4WZna0wjm0w"
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" -H "Authorization: Bearer ${ADMIN_JWT}" | grep "HTTP/1.1")
RETURN_CODE=$?
if [[ "$RESULT" == "HTTP/1.1 200 OK" ]]
then
  echo "[OK] ${TEST_PATH} (200)"
else
  echo "[FAIL] ${TEST_PATH} (200)"
fi
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" | grep "HTTP/1.1")
RETURN_CODE=$?
if [[ "$RESULT" == "HTTP/1.1 401 Unauthorized" ]]
then
  echo "[OK] ${TEST_PATH} (401)"
else
  echo "[FAIL] ${TEST_PATH} (401)"
fi

###############################################################################
# Test /echo-acl/admin
TEST_PATH="/echo-acl/admin"
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" -H "Authorization: Bearer ${ADMIN_JWT}" | grep "HTTP/1.1")
RETURN_CODE=$?
if [[ "$RESULT" == "HTTP/1.1 200 OK" ]]
then
  echo "[OK] ${TEST_PATH} (200)"
else
  echo "[FAIL] ${TEST_PATH} (200)"
fi
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" -H "Authorization: Bearer ${USER_JWT}" | grep "HTTP/1.1")
RETURN_CODE=$?
if [[ "$RESULT" == "HTTP/1.1 403 Forbidden" ]]
then
  echo "[OK] ${TEST_PATH} (403)"
else
  echo "[FAIL] ${TEST_PATH} (403)"
fi
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" | grep "HTTP/1.1")
RETURN_CODE=$?
if [[ "$RESULT" == "HTTP/1.1 401 Unauthorized" ]]
then
  echo "[OK] ${TEST_PATH} (401)"
else
  echo "[FAIL] ${TEST_PATH} (401)"
fi

# Test /echo-acl/anyone
TEST_PATH="/echo-acl/anyone"
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" -H "Authorization: Bearer ${USER_JWT}" | grep "HTTP/1.1")
RETURN_CODE=$?
if [[ "$RESULT" == "HTTP/1.1 200 OK" ]]
then
  echo "[OK] ${TEST_PATH} (200)"
else
  echo "[FAIL] ${TEST_PATH} (200)"
fi
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" | grep "HTTP/1.1")
RETURN_CODE=$?
if [[ "$RESULT" == "HTTP/1.1 401 Unauthorized" ]]
then
  echo "[OK] ${TEST_PATH} (401)"
else
  echo "[FAIL] ${TEST_PATH} (401)"
fi

###############################################################################
# Test /echo-jwtchecker
TEST_PATH="/echo-jwtchecker"
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" -H "Authorization: Bearer ${USER_JWT}" | grep "HTTP/1.1")
RETURN_CODE=$?
if [[ "$RESULT" == "HTTP/1.1 200 OK" ]]
then
  echo "[OK] ${TEST_PATH} (200)"
else
  echo "[FAIL] ${TEST_PATH} (200)"
fi
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" -H "Authorization: Bearer test" | grep "HTTP/1.1")
RETURN_CODE=$?
if [[ "$RESULT" == "HTTP/1.1 403 Forbidden" ]]
then
  echo "[OK] ${TEST_PATH} (403)"
else
  echo "[FAIL] ${TEST_PATH} (403)"
fi
RESULT=$(curl -s -i "http://localhost${TEST_PATH}" | grep "HTTP/1.1")
RETURN_CODE=$?
if [[ "$RESULT" == "HTTP/1.1 401 Unauthorized" ]]
then
  echo "[OK] ${TEST_PATH} (401)"
else
  echo "[FAIL] ${TEST_PATH} (401)"
fi




echo ""
read -p "Press any key to continue" x