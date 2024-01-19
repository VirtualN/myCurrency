//
//  ViewController.m
//  MyCurrency
//
//  Created by user225081 on 8/14/23.
//

#import "ViewController.h"

@interface ViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *currencies;
@property (nonatomic, weak) IBOutlet UIPickerView *fromCurrencyPicker;
@property (nonatomic, weak) IBOutlet UIPickerView *toCurrencyPicker;
@property (nonatomic, weak) IBOutlet UITextField *amountTextField;
@property (nonatomic, weak) IBOutlet UILabel *resultLabel;
@property (strong, nonatomic) IBOutlet UIButton *convertButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL isBookmarked;
@property (nonatomic, strong) NSMutableArray *exchangeRates; // Array per conservare i dati dei tassi di cambio
@property (weak, nonatomic) IBOutlet UIButton *loadButton;
@property (weak, nonatomic) IBOutlet UILabel *HistoricalChangeLabel;
@property (nonatomic, strong) NSMutableArray *selectedCurrencies;

@property (weak, nonatomic) IBOutlet UIButton *bookMark;

- (IBAction)saveCurrency:(id)sender;

- (IBAction)convertButtonTapped:(id)sender;

- (IBAction)LoadButtonTapped:(id)sender;

- (void)fetchExchangeRateFromAPIForCurrency:(NSString *)fromCurrency toCurrency:(NSString *)toCurrency amount:(double)amount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Inizializza l'array delle valute
    self.currencies = @[@"EUR", @"USD", @"JPY", @"GBP", @"AUD"];
    self.fromCurrencyPicker.dataSource = self;
    self.fromCurrencyPicker.delegate = self;
    self.toCurrencyPicker.dataSource = self;
    self.toCurrencyPicker.delegate = self;
    self.HistoricalChangeLabel.hidden = YES;
    self.isBookmarked = NO;
    
    self.selectedCurrencies = [NSMutableArray arrayWithArray:@[@"EUR", @"USD"]];
}

- (void)updateUI {
    if (self.exchangeRates.count >= 7) {
        // Rimuovi la vista della tabella esistente, se presente
        [self.tableView removeFromSuperview];
        
        // Altezza desiderata per la tabella (puoi regolarla a seconda delle tue esigenze)
        CGFloat tableHeight = 350.0;
        
        // Crea una tabella per visualizzare i dati
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.view.bounds) - tableHeight, self.view.bounds.size.width, tableHeight) style:UITableViewStylePlain];
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:tableView];
        self.tableView = tableView; // Assegna la tabella alla tua variabile di istanza
        
        // Ricarica la tabella per visualizzare i dati
        [tableView reloadData];
        self.HistoricalChangeLabel.hidden = NO;
        
    } else {
        // Gestire il caso in cui non ci siano dati sufficienti
        NSLog(@"Non ci sono dati sufficienti per visualizzare la tabella.");
        self.HistoricalChangeLabel.hidden = YES;
    }
}


- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView { 
    return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component { 
    return self.currencies.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.currencies[row];
}

// Azione del pulsante di conversione
- (IBAction)convertButtonTapped:(id)sender {
    NSInteger fromCurrencyIndex = [self.fromCurrencyPicker selectedRowInComponent:0];
    NSInteger toCurrencyIndex = [self.toCurrencyPicker selectedRowInComponent:0];
    
    NSString *fromCurrency = self.currencies[fromCurrencyIndex];
    NSString *toCurrency = self.currencies[toCurrencyIndex];
    
    double amount = [self.amountTextField.text doubleValue];
    
    [self fetchExchangeRatesForLast7DaysForCurrency:fromCurrency toCurrency:toCurrency];
    
    [self fetchExchangeRateFromAPIForCurrency:fromCurrency toCurrency:toCurrency amount:amount];
}

- (IBAction)saveCurrency:(id)sender {
    self.isBookmarked = !self.isBookmarked;
    
    if (self.isBookmarked) {
            // Se il bookmark è attivo, aggiorna l'array con i valori attuali dei picker
            NSInteger fromCurrencyIndex = [self.fromCurrencyPicker selectedRowInComponent:0];
            NSInteger toCurrencyIndex = [self.toCurrencyPicker selectedRowInComponent:0];

            NSString *fromCurrency = self.currencies[fromCurrencyIndex];
            NSString *toCurrency = self.currencies[toCurrencyIndex];

            self.selectedCurrencies = [NSMutableArray arrayWithArray:@[fromCurrency, toCurrency]];
        } else {
            // Se il bookmark è disattivato, ripristina l'array con le valute salvate
            // Puoi modificare questa parte per riflettere come hai inizializzato l'array iniziale
            self.selectedCurrencies = [NSMutableArray arrayWithArray:@[@"EUR", @"USD"]];
        }
        // Se il pulsante è contrassegnato, imposta l'immagine a "star.fill", altrimenti a "star"
        UIImage *buttonImage = self.isBookmarked ? [UIImage systemImageNamed:@"bookmark.fill"] : [UIImage systemImageNamed:@"bookmark"];
        [self.bookMark setImage:buttonImage forState:UIControlStateNormal];
    
}

- (void)fetchExchangeRatesForLast7DaysForCurrency:(NSString *)fromCurrency toCurrency:(NSString *)toCurrency {
    self.exchangeRates = [NSMutableArray array]; // Resetta l'array dei tassi di cambio
    
    // Imposta la data di fine (oggi) e la data di inizio (7 giorni fa)
    NSDate *endDate = [NSDate date];
    NSDate *startDate = [endDate dateByAddingTimeInterval:-7 * 24 * 60 * 60]; // Sottrai 7 giorni
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    // Esegue una richiesta API per ciascun giorno nell'intervallo
    while ([startDate compare:endDate] == NSOrderedAscending) {
        
        NSString *apiKey = @"862d7b229f4c0876c4d16766072b423f"; ;
        NSString *apiURL = [NSString stringWithFormat:@"https://api.exchangeratesapi.io/v1/%@?access_key=%@&base=%@&symbols=%@", [dateFormatter stringFromDate:startDate], apiKey, fromCurrency, toCurrency];
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:apiURL]];
        
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error == nil) {
                NSError *jsonError;
                NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                
                if (!jsonError && jsonResponse[@"rates"]) {
                    // Estrai i dati dei tassi di cambio e aggiungili all'array
                    [self.exchangeRates addObject:jsonResponse];
                    
                    
                    // Ordina l'array per data
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
                    [self.exchangeRates sortUsingDescriptors:@[sortDescriptor]];
                    
                    // Verifica se abbiamo ottenuto dati per gli ultimi 7 giorni
                    if (self.exchangeRates.count == 7) {
                        // Aggiorna l'interfaccia utente con i dati aggiornati
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self updateUI];
                        });
                    }
                }
            } else {
                NSLog(@"Errore nella richiesta API: %@", error.localizedDescription);
            }
        }];
        
        [task resume];
        
        // Passa al giorno successivo
        startDate = [startDate dateByAddingTimeInterval:24 * 60 * 60];
    }
}


- (void)fetchExchangeRateFromAPIForCurrency:(NSString *)fromCurrency toCurrency:(NSString *)toCurrency amount:(double)amount {
    NSString *apiKey = @"862d7b229f4c0876c4d16766072b423f"; // chiave API
    NSString *convertEndpoint = [NSString stringWithFormat:@"https://api.exchangeratesapi.io/v1/convert?access_key=%@&from=%@&to=%@&amount=%.2f", apiKey, fromCurrency, toCurrency, amount];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:convertEndpoint];
    
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Errore durante la richiesta API: %@", error);
            return;
        }
        
        NSError *jsonError = nil;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (jsonError) {
            NSLog(@"Errore durante il parsing JSON: %@", jsonError);
            return;
        }
        
        NSNumber *convertedAmount = responseDict[@"result"];
        if (convertedAmount) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.resultLabel.text = [NSString stringWithFormat:@"%.2f %@ = %.2f %@", amount, fromCurrency, convertedAmount.doubleValue, toCurrency];
            });
        } else {
            NSLog(@"Risultato di conversione non disponibile");
        }
    }];
    
    [task resume];
}

- (IBAction)LoadButtonTapped:(id)sender {
    if (self.selectedCurrencies.count == 2) {
            // Imposta i valori nei picker
            NSString *fromCurrency = self.selectedCurrencies[0];
            NSString *toCurrency = self.selectedCurrencies[1];

            [self.fromCurrencyPicker selectRow:[self.currencies indexOfObject:fromCurrency] inComponent:0 animated:YES];
            [self.toCurrencyPicker selectRow:[self.currencies indexOfObject:toCurrency] inComponent:0 animated:YES];
        }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.exchangeRates.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellIdentifier"];
    }
    
    // Estrai i dati del tasso di cambio per il giorno corrente
    NSDictionary *exchangeRateData = self.exchangeRates[indexPath.row];
    
    NSInteger toCurrencyIndex = [self.toCurrencyPicker selectedRowInComponent:0];
    NSString *toCurrency = self.currencies[toCurrencyIndex];
    
    // Estrai la data e il tasso di cambio dalla risposta API
    NSString *date = exchangeRateData[@"date"];
    NSNumber *exchangeRate = exchangeRateData[@"rates"][toCurrency]; // Modifica "GBP" con la valuta target desiderata
    
    // Mostra la data e il tasso di cambio nella cella
    cell.textLabel.text = [NSString stringWithFormat:@" %@ : %.6f", date, exchangeRate.floatValue];
    
    return cell;
}

@end
