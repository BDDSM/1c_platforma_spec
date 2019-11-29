﻿
Процедура ОбработкаПроведения(Отказ, Режим)
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	УчетнаяПолитикаСрезПоследних.МетодСписания КАК МетодСписания
		|ИЗ
		|	РегистрСведений.УчетнаяПолитика.СрезПоследних(&Дата, ) КАК УчетнаяПолитикаСрезПоследних";
	
	Запрос.УстановитьПараметр("Дата", Дата);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
		МетодСписания = ВыборкаДетальныеЗаписи.МетодСписания;
	КонецЦикла;
	
	Движения.ОстаткиНоменклатуры.Записывать = Истина;
	
	Движения.ОстаткиНоменклатуры.Записать();
	
	Блокировка = Новый БлокировкаДанных;
	ЭлементБлокировки = Блокировка.Добавить("РегистрНакопления.ОстаткиНоменклатуры");
	ЭлементБлокировки.Режим = РежимБлокировкиДанных.Исключительный;
	
	ЭлементБлокировки.ИсточникДанных = СписокНоменклатуры;
	ЭлементБлокировки.ИспользоватьИзИсточникаДанных("Номенклатура", "Номенклатура");
	Блокировка.Заблокировать();

	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	РасходнаяНакладнаяСписокНоменклатуры.Номенклатура КАК Номенклатура,
	|	СУММА(РасходнаяНакладнаяСписокНоменклатуры.Количество) КАК КоличествоДок
	|ПОМЕСТИТЬ ВТ_НомДокумента
	|ИЗ
	|	Документ.РасходнаяНакладная.СписокНоменклатуры КАК РасходнаяНакладнаяСписокНоменклатуры
	|ГДЕ
	|	РасходнаяНакладнаяСписокНоменклатуры.Ссылка = &Ссылка
	|
	|СГРУППИРОВАТЬ ПО
	|	РасходнаяНакладнаяСписокНоменклатуры.Номенклатура
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ВТ_НомДокумента.Номенклатура КАК Номенклатура,
	|	ВТ_НомДокумента.Номенклатура.Представление КАК НоменклатураПредставление,
	|	ВТ_НомДокумента.КоличествоДок КАК КоличествоДок,
	|	ОстаткиНоменклатурыОстатки.Партия КАК Партия,
	|	ЕСТЬNULL(ОстаткиНоменклатурыОстатки.КоличествоОстаток, 0) КАК КоличествоОстаток,
	|	ЕСТЬNULL(ОстаткиНоменклатурыОстатки.СуммаОстаток, 0) КАК СуммаОстаток
	|ИЗ
	|	ВТ_НомДокумента КАК ВТ_НомДокумента
	|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрНакопления.ОстаткиНоменклатуры.Остатки(
	|				&МоментВремени,
	|				Номенклатура В
	|					(ВЫБРАТЬ
	|						ВТ_НомДокумента.Номенклатура
	|					ИЗ
	|						ВТ_НомДокумента)) КАК ОстаткиНоменклатурыОстатки
	|		ПО ВТ_НомДокумента.Номенклатура = ОстаткиНоменклатурыОстатки.Номенклатура
	|
	|УПОРЯДОЧИТЬ ПО
	//|	Номенклатура,
	|	Партия.МоментВремени УБЫВ
	|ИТОГИ
	|	МАКСИМУМ(КоличествоДок),
	|	СУММА(КоличествоОстаток)
	|ПО
	|	Номенклатура";
	
	Если МетодСписания = ПредопределенноеЗначение("Перечисление.УчетнаяПолитика.ФИФО") Тогда
	
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "Партия.МоментВремени УБЫВ", "Партия.МоментВремени");
	
	КонецЕсли; 
	
	Запрос.УстановитьПараметр("МоментВремени", МоментВремени());
	Запрос.УстановитьПараметр("Ссылка", Ссылка);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаНоменклатура = РезультатЗапроса.Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);
	
	Пока ВыборкаНоменклатура.Следующий() Цикл
		
		Если ВыборкаНоменклатура.КОличествоДок > ВыборкаНоменклатура.КоличествоОстаток Тогда
			
			Сообщить("Не хватает товара: " + ВыборкаНоменклатура.НоменклатураПредставление + " в количестве: " + ВыборкаНоменклатура.КоличествоДок - ВыборкаНоменклатура.КоличествоОстаток);
			Отказ = Истина;
			Продолжить;
			
		КонецЕсли; 
		
		Если НЕ Отказ Тогда
			
			ОстатокДляСписания = ВыборкаНоменклатура.КоличествоДок;
			
			ВыборкаДетальныеЗаписи = ВыборкаНоменклатура.Выбрать();
			
			// регистр ОстаткиНоменклатуры Расход
			Пока ОстатокДляСписания> 0 И ВыборкаДетальныеЗаписи.Следующий() Цикл
				
				Движение = Движения.ОстаткиНоменклатуры.Добавить();
				Движение.ВидДвижения = ВидДвиженияНакопления.Расход;
				Движение.Период = Дата;
				Движение.Номенклатура = ВыборкаДетальныеЗаписи.Номенклатура;
				Движение.Партия = ВыборкаДетальныеЗаписи.Партия;
				
				Движение.Количество = МИН(ВыборкаДетальныеЗаписи.КоличествоОстаток, ОстатокДляСписания);
				
				ОстатокДляСписания = ОстатокДляСписания - Движение.Количество;
				
				СуммаСписания = ?(Движение.Количество = ВыборкаДетальныеЗаписи.КоличествоОстаток, 
				ВыборкаДетальныеЗаписи.СуммаОстаток, 
				ВыборкаДетальныеЗаписи.СуммаОстаток / ВыборкаДетальныеЗаписи.КоличествоОстаток * Движение.Количество);
				
				Движение.Сумма = СуммаСписания;
				
			КонецЦикла;
			
		КонецЕсли;
	КонецЦикла;
	
	//{{__КОНСТРУКТОР_ДВИЖЕНИЙ_РЕГИСТРОВ
	// Данный фрагмент построен конструктором.
	// При повторном использовании конструктора, внесенные вручную изменения будут утеряны!!!

	//}}__КОНСТРУКТОР_ДВИЖЕНИЙ_РЕГИСТРОВ
КонецПроцедуры
