create table if not exists employee
(id_employee integer primary key,
phone_employee varchar(20) NOT NULL CHECK (LENGTH(phone_employee) = 10),
login_employee varchar(20) NOT NULL,
sex_employee varchar(20) NOT NULL,
bithrday_employee date NOT NULL,
passport_employee varchar(10) NOT NULL CHECK (LENGTH(passport_employee) = 10),
name_employee varchar(20) NOT NULL,
inn_employee integer NOT NULL,
date_join_employee date NOT NULL,
date_out_employee date NOT NULL,
main_director_employee int,
FOREIGN KEY (main_director_employee) REFERENCES employee ON DELETE CASCADE ON UPDATE CASCADE,
CHECK (date_join_employee < date_out_employee)
);

create table if not exists employee_pos
(id_employee_pos integer primary key,
code_employee_pos int NOT NULL,
name_employee_pos varchar(20) NOT NULL);

create table if not exists employeers_of_position
(id_employeers_of_position integer primary key,
cost_employeers_of_position integer NULL,
id_employee_pos integer NOT NULL,
id_employee integer NOT NULL,
FOREIGN KEY (id_employee_pos) REFERENCES employee_pos ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (id_employee) REFERENCES employee ON DELETE CASCADE ON UPDATE CASCADE
);

create table if not exists group_products
(id_group_products integer primary key,
name_group_products varchar(30) NOT NULL,
description_group_products varchar(50) NULL,
parent_group_products int,
FOREIGN KEY(parent_group_products) REFERENCES group_products ON DELETE CASCADE ON UPDATE CASCADE);

create table if not exists country_origin
(id_country_origin integer primary key,
name_country_origin varchar(20) NOT NULL,
phone_country_origin varchar(20) NOT NULL CHECK (LENGTH(phone_country_origin) = 10),
abbrevation_country_origin varchar(20) NOT NULL);

create table if not exists product
(id_product integer primary key,
package_product varchar(20) NULL,
num_certificate_product integer NOT NULL,
articul_product integer NOT NULL,
name_product varchar(20) NOT NULL,
name_company_manufacturer_product varchar(20) NOT NULL,
value_sklad_product integer NULL,
id_country_origin integer NOT NULL,
id_tovaroved integer NOT NULL,
FOREIGN KEY (id_country_origin) REFERENCES country_origin ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (id_tovaroved) REFERENCES employee ON DELETE CASCADE ON UPDATE CASCADE
);

create table if not exists products_of_group_products
(id_products_of_group_products integer primary key,
value_products_of_group_products integer NULL,
id_group_products integer NOT NULL,
id_product integer NOT NULL,
FOREIGN KEY (id_product) REFERENCES product ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (id_group_products) REFERENCES group_products ON DELETE CASCADE ON UPDATE CASCADE);

create table if not exists money_unit
(id_money_unit integer primary key,
name_money_unit varchar (20) NOT NULL,
id_country_origin integer NOT NULL,
FOREIGN KEY (id_country_origin) REFERENCES country_origin ON DELETE CASCADE ON UPDATE CASCADE
);

create table if not exists exchange_money
(id_exchange_money integer primary key,
date_exchange_money date NOT NULL,
value_exchange_money float,
reverse_value_exchange_money float,
id_money_unit1 integer NOT NULL CHECK (id_money_unit1 > 0),
id_money_unit2 integer NOT NULL CHECK (id_money_unit2 > 0),
FOREIGN KEY (id_money_unit1) REFERENCES money_unit ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (id_money_unit2) REFERENCES money_unit ON DELETE CASCADE ON UPDATE CASCADE
);

create table if not exists buyer_company
(id_buyer_company integer primary key,
num_license_buyer_company varchar(20) NOT NULL,
adress_buyer_company varchar(40) NOT NULL,
name_buyer_company varchar(20) NOT NULL,
phone_buyer_company varchar(20) NOT NULL CHECK (LENGTH(phone_buyer_company) = 10),
bank_value_buyer_company integer NOT NULL,
category_buyer_company varchar(20) NOT NULL,
id_money_unit integer NOT NULL,
FOREIGN KEY (id_money_unit) REFERENCES money_unit ON DELETE CASCADE ON UPDATE CASCADE
);

create table if not exists pay_document
(id_pay_document integer primary key,
sum_pay_document integer NULL,
date_create_pay_document date NOT NULL,
num_pp_ident_buyings_pay_document integer NOT NULL,
type_pay_document varchar(20) NOT NULL,
num_pp_ident_bank integer NOT NULL,
id_money_unit integer NOT NULL,
id_buhgalter integer NOT NULL,
FOREIGN KEY (id_money_unit) REFERENCES money_unit ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (id_buhgalter) REFERENCES employee ON DELETE CASCADE ON UPDATE CASCADE
);

create table if not exists string_product_document
(id_string_product_document integer primary key,
date_add_string_product_document date NOT NULL,
id_pay_document integer NOT NULL,
FOREIGN KEY (id_pay_document) REFERENCES pay_document ON DELETE CASCADE ON UPDATE CASCADE);

create table if not exists product_document
(id_product_document integer primary key,
num_product_document integer,
num_product_document_pp integer,
name_product_document varchar(20) NOT NULL,
sum_pay_document integer,
type_product_document varchar(20) NOT NULL,
date_sale_product_document date,
date_return_product_document date,
date_creat_product_document date NOT NULL,
id_string_product_document integer NOT NULL,
id_manager integer NOT NULL,
id_buyer_company integer NOT NULL,
id_money_unit integer NOT NULL,
FOREIGN KEY (id_string_product_document) REFERENCES string_product_document ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (id_manager) REFERENCES employee ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (id_buyer_company) REFERENCES buyer_company ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (id_money_unit) REFERENCES money_unit ON DELETE CASCADE ON UPDATE CASCADE,
CHECK (date_sale_product_document < date_return_product_document),
CHECK (date_creat_product_document <= date_sale_product_document)
);

create table if not exists products_of_product_document
(id_products_of_product_document integer primary key,
value_id_products_of_product_document integer NOT NULL,
id_product_document integer NOT NULL,
id_product integer NOT NULL,
FOREIGN KEY (id_product_document) REFERENCES product_document ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (id_product) REFERENCES product ON DELETE CASCADE ON UPDATE CASCADE
);
--------------------------------
CREATE OR REPLACE FUNCTION check_product_document()
RETURNS TRIGGER AS $$
DECLARE
    name_exists varchar(20);
    sum_pay integer;
BEGIN
    IF NEW.type_product_document ='output' THEN
	    SELECT name_product_document, sum_pay_document INTO name_exists, sum_pay
		FROM product_document
		WHERE name_product_document = NEW.name_product_document;
		END IF;
    IF NEW.sum_pay_document < 0 THEN
            RAISE EXCEPTION 'Sum pay is negative'; /*выдаем ошибку*/
        END IF;
	IF NEW.sum_pay_document IS NULL THEN
	        NEW.sum_pay_document = 0;
            RAISE NOTICE 'Sum pay is not defined';
			RETURN NEW;
        END IF;
    IF NEW.sum_pay_document > 0 THEN
	        RETURN NEW;
	    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER product_document_check
BEFORE INSERT ON product_document
FOR EACH ROW
EXECUTE FUNCTION check_product_document();
--------------------------------aaaaaaa

--------------------------------aaaaaaa
CREATE OR REPLACE FUNCTION calculate_reverse_value_exchange_money()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.date_exchange_money IS NOT NULL 
	AND NEW.value_exchange_money IS NOT NULL 
	AND NEW.reverse_value_exchange_money IS NULL THEN
        NEW.reverse_value_exchange_money = (1/NEW.value_exchange_money) * 1.05;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_reverse_value_exchange_money
BEFORE INSERT ON exchange_money
FOR EACH ROW
EXECUTE FUNCTION calculate_reverse_value_exchange_money();
--------------------------------
INSERT INTO employee (id_employee, phone_employee, login_employee, sex_employee, bithrday_employee, passport_employee, name_employee, inn_employee, date_join_employee, date_out_employee, main_director_employee)
VALUES (6, '7777777777', 'jim_brown', 'Male', '1991-06-20', 'UV99999999', 'Jim Brown', 777777777, '2020-07-01', '2022-07-01', null);

INSERT INTO employee (id_employee, phone_employee, login_employee, sex_employee, bithrday_employee, passport_employee, name_employee, inn_employee, date_join_employee, date_out_employee, main_director_employee)
VALUES (7, '8888888888', 'amy_jones', 'Female', '1993-02-11', 'WX11111111', 'Amy Jones', 888888888, '2019-08-01', '2022-08-01', null);

INSERT INTO employee (id_employee, phone_employee, login_employee, sex_employee, bithrday_employee, passport_employee, name_employee, inn_employee, date_join_employee, date_out_employee, main_director_employee)
VALUES (8, '9999999999', 'steve_smith', 'Male', '1994-11-30', 'YZ22222222', 'Steve Smith', 999999999, '2021-01-01', '2022-08-01', 7);

INSERT INTO employee (id_employee, phone_employee, login_employee, sex_employee, bithrday_employee, passport_employee, name_employee, inn_employee, date_join_employee, date_out_employee, main_director_employee)
VALUES (9, '1111111111', 'emily_brown', 'Female', '1989-04-05', 'AB33333333', 'Emily Brown', 111111111, '2018-05-01', '2023-05-01', 6);

INSERT INTO employee (id_employee, phone_employee, login_employee, sex_employee, bithrday_employee, passport_employee, name_employee, inn_employee, date_join_employee, date_out_employee, main_director_employee)
VALUES (10, '2222222222', 'dave_wilson', 'Male', '1996-09-18', 'CD44444444', 'Dave Wilson', 222222222, '2020-02-01', '2022-08-01', 7);


INSERT INTO employee_pos (id_employee_pos, code_employee_pos, name_employee_pos) VALUES (1, 101, 'Manager');
INSERT INTO employee_pos (id_employee_pos, code_employee_pos, name_employee_pos) VALUES (2, 102, 'Sales Representative');
INSERT INTO employee_pos (id_employee_pos, code_employee_pos, name_employee_pos) VALUES (3, 103, 'Accountant');
INSERT INTO employee_pos (id_employee_pos, code_employee_pos, name_employee_pos) VALUES (4, 104, 'HR Specialist');
INSERT INTO employee_pos (id_employee_pos, code_employee_pos, name_employee_pos) VALUES (5, 105, 'Software Engineer');
INSERT INTO employee_pos (id_employee_pos, code_employee_pos, name_employee_pos) VALUES (6, 106, 'Web Developer');
INSERT INTO employee_pos (id_employee_pos, code_employee_pos, name_employee_pos) VALUES (7, 107, 'System Administrator');
INSERT INTO employee_pos (id_employee_pos, code_employee_pos, name_employee_pos) VALUES (8, 108, 'Marketing Specialist');

INSERT INTO employeers_of_position (id_employeers_of_position, cost_employeers_of_position, id_employee_pos, id_employee) VALUES (1, 321, 1, 6);
INSERT INTO employeers_of_position (id_employeers_of_position, cost_employeers_of_position, id_employee_pos, id_employee) VALUES (2, 5, 2, 7);
INSERT INTO employeers_of_position (id_employeers_of_position, cost_employeers_of_position, id_employee_pos, id_employee) VALUES (3, 10, 3, 8);
INSERT INTO employeers_of_position (id_employeers_of_position, cost_employeers_of_position, id_employee_pos, id_employee) VALUES (4, 13, 4, 9);
INSERT INTO employeers_of_position (id_employeers_of_position, cost_employeers_of_position, id_employee_pos, id_employee) VALUES (5, 32, 5, 6);
INSERT INTO employeers_of_position (id_employeers_of_position, cost_employeers_of_position, id_employee_pos, id_employee) VALUES (6, 151, 6, 7);
INSERT INTO employeers_of_position (id_employeers_of_position, cost_employeers_of_position, id_employee_pos, id_employee) VALUES (7, 200, 7, 7);
INSERT INTO employeers_of_position (id_employeers_of_position, cost_employeers_of_position, id_employee_pos, id_employee) VALUES (8, 1, 8, 8);

INSERT INTO group_products (id_group_products, name_group_products, description_group_products, parent_group_products) VALUES (1, 'Computers', 'Computers and related products', NULL);
INSERT INTO group_products (id_group_products, name_group_products, description_group_products, parent_group_products) VALUES (2, 'Laptops', 'Laptop computers and accessories', 1);
INSERT INTO group_products (id_group_products, name_group_products, description_group_products, parent_group_products) VALUES (3, 'Desktops', 'Desktop computers and accessories', 1);
INSERT INTO group_products (id_group_products, name_group_products, description_group_products, parent_group_products) VALUES (4, 'Peripherals', 'Computer peripherals and accessories', 1);
INSERT INTO group_products (id_group_products, name_group_products, description_group_products, parent_group_products) VALUES (5, 'Printers', 'Printers and printer supplies', 4);
INSERT INTO group_products (id_group_products, name_group_products, description_group_products, parent_group_products) VALUES (6, 'Monitors', 'Computer monitors and displays', 4);
INSERT INTO group_products (id_group_products, name_group_products, description_group_products, parent_group_products) VALUES (7, 'Components', 'Computer components and parts', 1);
INSERT INTO group_products (id_group_products, name_group_products, description_group_products, parent_group_products) VALUES (8, 'Hard Drives', 'Internal and external hard drives', 7);

INSERT INTO country_origin (id_country_origin, name_country_origin, phone_country_origin, abbrevation_country_origin) VALUES (1, 'United States', '1234567890', 'USA');
INSERT INTO country_origin (id_country_origin, name_country_origin, phone_country_origin, abbrevation_country_origin) VALUES (2, 'Canada', '0987654321', 'CAN');
INSERT INTO country_origin (id_country_origin, name_country_origin, phone_country_origin, abbrevation_country_origin) VALUES (3, 'United Kingdom', '5555555555', 'UK');
INSERT INTO country_origin (id_country_origin, name_country_origin, phone_country_origin, abbrevation_country_origin) VALUES (4, 'France', '1111111111', 'FRA');
INSERT INTO country_origin (id_country_origin, name_country_origin, phone_country_origin, abbrevation_country_origin) VALUES (5, 'Germany', '2222222222', 'GER');
INSERT INTO country_origin (id_country_origin, name_country_origin, phone_country_origin, abbrevation_country_origin) VALUES (6, 'Italy', '3333333333', 'ITA');
INSERT INTO country_origin (id_country_origin, name_country_origin, phone_country_origin, abbrevation_country_origin) VALUES (7, 'Japan', '4444444444', 'JPN');
INSERT INTO country_origin (id_country_origin, name_country_origin, phone_country_origin, abbrevation_country_origin) VALUES (8, 'China', '5555555555', 'CHN');

INSERT INTO product (id_product, package_product, num_certificate_product, articul_product, name_product, name_company_manufacturer_product, value_sklad_product, id_country_origin, id_tovaroved) VALUES (1, 'Box', 1234, 5678, 'Samsong G21', 'Watermelon Inc.', 100, 1, 8);
INSERT INTO product (id_product, package_product, num_certificate_product, articul_product, name_product, name_company_manufacturer_product, value_sklad_product, id_country_origin, id_tovaroved) VALUES (2, 'Bag', 2345, 6789, 'iFone 11', 'Mike', 200, 2, 9);
INSERT INTO product (id_product, package_product, num_certificate_product, articul_product, name_product, name_company_manufacturer_product, value_sklad_product, id_country_origin, id_tovaroved) VALUES (3, 'Box', 3456, 7890, 'Ksuyaomi Lap3', 'Burger MadamSir', 300, 3, 8);
INSERT INTO product (id_product, package_product, num_certificate_product, articul_product, name_product, name_company_manufacturer_product, value_sklad_product, id_country_origin, id_tovaroved) VALUES (4, 'Bag', 4567, 8901, 'MakBok i3', 'MasterBeef', 400, 4,9);
INSERT INTO product (id_product, package_product, num_certificate_product, articul_product, name_product, name_company_manufacturer_product, value_sklad_product, id_country_origin, id_tovaroved) VALUES (5, 'Box', 5678, 9012, 'Bosher 3000', 'SunBucks Cofee', 500, 5, 8);
INSERT INTO product (id_product, package_product, num_certificate_product, articul_product, name_product, name_company_manufacturer_product, value_sklad_product, id_country_origin, id_tovaroved) VALUES (6, 'Bag', 6789, 0123, 'Canan Cam 3x213U', 'Pizza Huh', 600, 6, 9);
INSERT INTO product (id_product, package_product, num_certificate_product, articul_product, name_product, name_company_manufacturer_product, value_sklad_product, id_country_origin, id_tovaroved) VALUES (7, 'Box', 7890, 1234, 'El Dji Monitor x51', 'Doodle', 700, 7, 8);
INSERT INTO product (id_product, package_product, num_certificate_product, articul_product, name_product, name_company_manufacturer_product, value_sklad_product, id_country_origin, id_tovaroved) VALUES (8, 'Bag', 8901, 2345, 'SuperFone 5', 'KFG', 800, 8, 8);


INSERT INTO products_of_group_products (id_products_of_group_products, value_products_of_group_products, id_group_products, id_product) VALUES (1, 10, 2, 1);
INSERT INTO products_of_group_products (id_products_of_group_products, value_products_of_group_products, id_group_products, id_product) VALUES (2, 20, 2, 2);
INSERT INTO products_of_group_products (id_products_of_group_products, value_products_of_group_products, id_group_products, id_product) VALUES (3, 30, 3, 3);
INSERT INTO products_of_group_products (id_products_of_group_products, value_products_of_group_products, id_group_products, id_product) VALUES (4, 40, 3, 4);
INSERT INTO products_of_group_products (id_products_of_group_products, value_products_of_group_products, id_group_products, id_product) VALUES (5, 50, 4, 5);
INSERT INTO products_of_group_products (id_products_of_group_products, value_products_of_group_products, id_group_products, id_product) VALUES (6, 60, 4, 6);
INSERT INTO products_of_group_products (id_products_of_group_products, value_products_of_group_products, id_group_products, id_product) VALUES (7, 70, 1, 7);
INSERT INTO products_of_group_products (id_products_of_group_products, value_products_of_group_products, id_group_products, id_product) VALUES (8, 80, 1, 8);

INSERT INTO money_unit (id_money_unit, name_money_unit, id_country_origin) VALUES (1, 'Dollar', 1);
INSERT INTO money_unit (id_money_unit, name_money_unit, id_country_origin) VALUES (2, 'Euro', 5);
INSERT INTO money_unit (id_money_unit, name_money_unit, id_country_origin) VALUES (3, 'Pound Sterling', 3);
INSERT INTO money_unit (id_money_unit, name_money_unit, id_country_origin) VALUES (4, 'Canadian Dollar', 2);
INSERT INTO money_unit (id_money_unit, name_money_unit, id_country_origin) VALUES (5, 'Yen', 7);
INSERT INTO money_unit (id_money_unit, name_money_unit, id_country_origin) VALUES (6, 'Renminbi', 8);
INSERT INTO money_unit (id_money_unit, name_money_unit, id_country_origin) VALUES (7, 'Swiss Franc', 6);
INSERT INTO money_unit (id_money_unit, name_money_unit, id_country_origin) VALUES (8, 'Russian Ruble', 3);

INSERT INTO exchange_money (id_exchange_money, date_exchange_money, value_exchange_money, reverse_value_exchange_money, id_money_unit1, id_money_unit2) VALUES (1, '2022-01-01', 70, null, 1, 2);
INSERT INTO exchange_money (id_exchange_money, date_exchange_money, value_exchange_money, reverse_value_exchange_money, id_money_unit1, id_money_unit2) VALUES (2, '2022-01-01', 64, 0.15, 1, 3);
INSERT INTO exchange_money (id_exchange_money, date_exchange_money, value_exchange_money, reverse_value_exchange_money, id_money_unit1, id_money_unit2) VALUES (3, '2022-01-01', 71, 0.13, 1, 4);
INSERT INTO exchange_money (id_exchange_money, date_exchange_money, value_exchange_money, reverse_value_exchange_money, id_money_unit1, id_money_unit2) VALUES (4, '2022-01-01', 84, 0.25, 1, 5);
INSERT INTO exchange_money (id_exchange_money, date_exchange_money, value_exchange_money, reverse_value_exchange_money, id_money_unit1, id_money_unit2) VALUES (5, '2022-01-01', 24, null, 1, 6);
INSERT INTO exchange_money (id_exchange_money, date_exchange_money, value_exchange_money, reverse_value_exchange_money, id_money_unit1, id_money_unit2) VALUES (6, '2022-01-01', 45, 0.1, 1, 7);
INSERT INTO exchange_money (id_exchange_money, date_exchange_money, value_exchange_money, reverse_value_exchange_money, id_money_unit1, id_money_unit2) VALUES (7, '2022-01-01', 39, 0.5, 1, 8);

-----ВСТАВКА ДЛЯ ПРОЦЕДУРЫ 1-------
INSERT INTO exchange_money (id_exchange_money, date_exchange_money, value_exchange_money, reverse_value_exchange_money, id_money_unit1, id_money_unit2) VALUES (1, '2021-01-01', 70, null, 1, 2);
INSERT INTO exchange_money (id_exchange_money, date_exchange_money, value_exchange_money, reverse_value_exchange_money, id_money_unit1, id_money_unit2) VALUES (2, '2021-01-01', 64, 0.15, 1, 3);
INSERT INTO exchange_money (id_exchange_money, date_exchange_money, value_exchange_money, reverse_value_exchange_money, id_money_unit1, id_money_unit2) VALUES (3, '2021-01-01', 71, 0.13, 1, 4);
INSERT INTO exchange_money (id_exchange_money, date_exchange_money, value_exchange_money, reverse_value_exchange_money, id_money_unit1, id_money_unit2) VALUES (4, '2021-01-01', 84, 0.25, 1, 5);
INSERT INTO exchange_money (id_exchange_money, date_exchange_money, value_exchange_money, reverse_value_exchange_money, id_money_unit1, id_money_unit2) VALUES (5, '2021-01-01', 24, null, 1, 6);
INSERT INTO exchange_money (id_exchange_money, date_exchange_money, value_exchange_money, reverse_value_exchange_money, id_money_unit1, id_money_unit2) VALUES (6, '2021-01-01', 45, 0.1, 1, 7);
INSERT INTO exchange_money (id_exchange_money, date_exchange_money, value_exchange_money, reverse_value_exchange_money, id_money_unit1, id_money_unit2) VALUES (7, '2021-01-01', 39, 0.5, 1, 8);

INSERT INTO buyer_company (id_buyer_company, num_license_buyer_company, adress_buyer_company, name_buyer_company, phone_buyer_company, bank_value_buyer_company, category_buyer_company, id_money_unit) VALUES (1, 1234567890, '123 Main St', 'ABC Company', '1234567890', 50000, 'shop', 1);
INSERT INTO buyer_company (id_buyer_company, num_license_buyer_company, adress_buyer_company, name_buyer_company, phone_buyer_company, bank_value_buyer_company, category_buyer_company, id_money_unit) VALUES (2, 0987654321, '456 Elm St', 'XYZ Corporation', '0987654321', 100000, 'wholesaler', 2);
INSERT INTO buyer_company (id_buyer_company, num_license_buyer_company, adress_buyer_company, name_buyer_company, phone_buyer_company, bank_value_buyer_company, category_buyer_company, id_money_unit) VALUES (3, 1357908642, '789 Oak St', 'LMN Industries', '1357908642', 75000, 'saler', 3);
INSERT INTO buyer_company (id_buyer_company, num_license_buyer_company, adress_buyer_company, name_buyer_company, phone_buyer_company, bank_value_buyer_company, category_buyer_company, id_money_unit) VALUES (4, 2468013579, '321 Maple St', 'PQR Enterprises', '2468013579', 125000, 'manufacture', 4);

INSERT INTO pay_document (id_pay_document, sum_pay_document, date_create_pay_document, num_pp_ident_buyings_pay_document, type_pay_document, num_pp_ident_bank, id_money_unit, id_buhgalter) VALUES (1, 5000, '2022-01-01', 1, 'Invoice', 1, 1, 6);
INSERT INTO pay_document (id_pay_document, sum_pay_document, date_create_pay_document, num_pp_ident_buyings_pay_document, type_pay_document, num_pp_ident_bank, id_money_unit, id_buhgalter) VALUES (2, 10000, '2022-01-02', 2, 'Outvoice', 2, 2, 6);
INSERT INTO pay_document (id_pay_document, sum_pay_document, date_create_pay_document, num_pp_ident_buyings_pay_document, type_pay_document, num_pp_ident_bank, id_money_unit, id_buhgalter) VALUES (3, -7500, '2022-01-03', 3, 'Invoice', 3, 3, 6);
INSERT INTO pay_document (id_pay_document, sum_pay_document, date_create_pay_document, num_pp_ident_buyings_pay_document, type_pay_document, num_pp_ident_bank, id_money_unit, id_buhgalter) VALUES (4, -12500, '2022-01-04', 4, 'Invoice', 4, 4, 6);
INSERT INTO pay_document (id_pay_document, sum_pay_document, date_create_pay_document, num_pp_ident_buyings_pay_document, type_pay_document, num_pp_ident_bank, id_money_unit, id_buhgalter) VALUES (5, 9000, '2022-01-05', 5, 'Outvoice', 5, 5, 6);
INSERT INTO pay_document (id_pay_document, sum_pay_document, date_create_pay_document, num_pp_ident_buyings_pay_document, type_pay_document, num_pp_ident_bank, id_money_unit, id_buhgalter) VALUES (6, 15000, '2022-01-06', 6, 'Outvoice', 6, 6, 6);
INSERT INTO pay_document (id_pay_document, sum_pay_document, date_create_pay_document, num_pp_ident_buyings_pay_document, type_pay_document, num_pp_ident_bank, id_money_unit, id_buhgalter) VALUES (7, null, '2022-01-07', 7, 'Outvoice', 7, 7, 7);
INSERT INTO pay_document (id_pay_document, sum_pay_document, date_create_pay_document, num_pp_ident_buyings_pay_document, type_pay_document, num_pp_ident_bank, id_money_unit, id_buhgalter) VALUES (8, null, '2022-01-08', 8, 'Invoice', 8, 8, 8);

INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (1, '2022-01-01', 1);
INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (2, '2022-01-02', 2);
INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (3, '2022-01-03', 3);
INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (4, '2022-01-04', 4);
INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (5, '2022-01-05', 5);
INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (6, '2022-01-06', 6);
INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (7, '2022-01-07', 7);
INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (8, '2022-01-08', 8);
INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (9, '2022-01-09', 1);
INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (10, '2022-01-10', 2);
INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (11, '2022-01-11', 3);
INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (12, '2022-01-12', 4);
INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (13, '2022-01-13', 5);
INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (14, '2022-01-14', 6);
INSERT INTO string_product_document (id_string_product_document, date_add_string_product_document, id_pay_document) VALUES (15, '2022-01-15', 7);

INSERT INTO product_document (id_product_document, num_product_document, num_product_document_pp, name_product_document, sum_pay_document, type_product_document, date_sale_product_document, date_return_product_document, date_creat_product_document, id_string_product_document, id_manager, id_buyer_company, id_money_unit) VALUES (1, 12345, 123, 'Product1', 5000, 'input', '2022-01-01', '2022-01-05', '2022-01-01', 1, 7, 1, 1);
INSERT INTO product_document (id_product_document, num_product_document, num_product_document_pp, name_product_document, sum_pay_document, type_product_document, date_sale_product_document, date_return_product_document, date_creat_product_document, id_string_product_document, id_manager, id_buyer_company, id_money_unit) VALUES (2, 23456, 234, 'Product2', -10000, 'output', '2022-01-02', '2022-01-06', '2022-01-02', 2, 8, 2, 2);
INSERT INTO product_document (id_product_document, num_product_document, num_product_document_pp, name_product_document, sum_pay_document, type_product_document, date_sale_product_document, date_return_product_document, date_creat_product_document, id_string_product_document, id_manager, id_buyer_company, id_money_unit) VALUES (3, 34567, 345, 'Product3', 7500, 'output', '2022-01-03', '2022-01-07', '2022-01-03', 3, 7, 3, 3);
INSERT INTO product_document (id_product_document, num_product_document, num_product_document_pp, name_product_document, sum_pay_document, type_product_document, date_sale_product_document, date_return_product_document, date_creat_product_document, id_string_product_document, id_manager, id_buyer_company, id_money_unit) VALUES (4, 45678, 456, 'Product4', null, 'output', '2022-01-04', '2022-01-08', '2022-01-04', 4, 8, 4, 4);

INSERT INTO products_of_product_document (id_products_of_product_document, value_id_products_of_product_document, id_product_document, id_product) VALUES (1, 100, 1, 1);
INSERT INTO products_of_product_document (id_products_of_product_document, value_id_products_of_product_document, id_product_document, id_product) VALUES (2, 200, 2, 2);
INSERT INTO products_of_product_document (id_products_of_product_document, value_id_products_of_product_document, id_product_document, id_product) VALUES (3, 150, 3, 3);
INSERT INTO products_of_product_document (id_products_of_product_document, value_id_products_of_product_document, id_product_document, id_product) VALUES (4, 400, 4, 4);

--













