require 'httparty'
require 'dotenv'
require 'date'
require 'dotenv/load'

def get_simple_quote(client_dni, debtor_dni, document_amount, folio, expiration_date)
    url = "https://chita.cl/api/v1/pricing/simple_quote"
    query_params = {
        client_dni: client_dni,
        debtor_dni: debtor_dni,
        document_amount: document_amount,
        folio: folio,
        expiration_date: expiration_date
    }
    headers = {
        'X-Api-Key' => ENV['CHITA_API_KEY']
    }
    response = HTTParty.get(url, query: query_params, headers: headers)
    response.parsed_response
end

def calcalate_finantial_cost(document_amount, advance_percent, document_rate, days)
    advance_amount = calculate_advance_amount(document_amount, advance_percent)
    business_rate = (document_rate / 100.0)/30.0 * days
    cost_of_financing = advance_amount * business_rate
    cost_of_financing
end

def calculate_amounts_to_receive(document_amount, advance_percent, cost_of_financing, commission)
    advance_amount = calculate_advance_amount(document_amount, advance_percent)
    
    amounts_to_receive = advance_amount - (cost_of_financing + commission)
    puts amounts_to_receive
    puts cost_of_financing
    puts commission
    surplus = document_amount - advance_amount
    [amounts_to_receive, surplus]
end

def calculate_advance_amount(document_amount, advance_percent)
    document_amount * (advance_percent / 100.0)
end

def format_number(number)
    parts = number.to_s.split('.')
    integer_part = parts[0].gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1.')
    integer_part
end

def main(client_dni, debtor_dni, document_amount, folio, expiration_date)
    response = get_simple_quote(client_dni, debtor_dni, document_amount, folio, expiration_date)
    
    document_rate = response['document_rate']
    commission = response['commission']
    advance_percent = response['advance_percent']

    today = Date.today
    expiration_date = Date.parse(expiration_date)
    days = (expiration_date - today).to_i + 1

    cost_of_financing = calcalate_finantial_cost(document_amount, advance_percent, document_rate, days)
    amounts_to_receive, surplus = calculate_amounts_to_receive(document_amount, advance_percent, cost_of_financing, commission)
    puts "Costo de financiamiento: $#{format_number(cost_of_financing.round(2))}"
    puts "Giro a recibir: $#{format_number(amounts_to_receive.round(2))}"
    puts "Excedentes: $#{format_number(surplus.round(2))}"
end

client_dni, debtor_dni, document_amount, folio, expiration_date = ARGV
main(client_dni, debtor_dni, document_amount.to_i, folio.to_i, expiration_date)