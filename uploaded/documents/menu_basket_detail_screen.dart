import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speedika_delivery/core/api_req/basket/basket_detail_api.dart';
import 'package:speedika_delivery/core/api_req/basket/basket_history_list_api.dart';
import 'package:speedika_delivery/core/config/country_data_config.dart';
import 'package:speedika_delivery/core/models/basket/basket_detail_model.dart';
import 'package:speedika_delivery/core/models/basket/basket_history_list_model.dart';
import 'package:speedika_delivery/core/provider/basket_and_table_provider.dart';
import 'package:speedika_delivery/core/service/date_service.dart';
import 'package:speedika_delivery/core/service/unit_service.dart';
import 'package:speedika_delivery/core/service/stringExtension.dart';
import 'package:speedika_delivery/core/service/numberExtension.dart';
import 'package:speedika_delivery/main.dart';
import 'package:speedika_delivery/styles/colors.dart';
import 'package:speedika_delivery/ui/screens/menu/menu_screen.dart';
import 'package:speedika_delivery/ui/widgets/CommonWidgets/Button.dart';
import 'package:speedika_delivery/values/status_values.dart';
import 'package:speedika_delivery/values/text_values.dart';
import 'package:blue_print_pos/blue_print_pos.dart';
import 'package:blue_print_pos/models/blue_device.dart';
import 'package:blue_print_pos/models/connection_status.dart';
import 'package:blue_print_pos/receipt/receipt_section_text.dart';
import 'package:blue_print_pos/receipt/receipt_text_size_type.dart';
import 'package:blue_print_pos/receipt/receipt_text_style_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class MenuBasketDetailScreen extends StatefulWidget {
  final String basketId;
  final VoidCallback updatedCallBack;

  const MenuBasketDetailScreen(
      {Key key, @required this.basketId, this.updatedCallBack})
      : super(key: key);

  @override
  _MenuBasketDetailScreenState createState() => _MenuBasketDetailScreenState();
}

class _MenuBasketDetailScreenState extends State<MenuBasketDetailScreen> {
  BasketDetailApi _basketDetailApi = new BasketDetailApi();
  BasketDetailModel _basketDetailModel = new BasketDetailModel();
  BasketHistoryListApi _basketHistoryListApi = new BasketHistoryListApi();
  BasketHistoryListModel _basketHistoryListModel = new BasketHistoryListModel();

  TextValues _textValues = new TextValues();
  StatusValue _statusValue = new StatusValue();
  DateService _dateService = DateService();

  num _totalTax = 0;
  num _totalDiscount = 0;

  String _basketId = '';
  bool _isLoading = true;
  final BluePrintPos _bluePrintPos = BluePrintPos.instance;
  List<BlueDevice> _blueDevices = <BlueDevice>[];
  BlueDevice _selectedDevice;
  bool _isLoading1 = false;
  int _loadingAtIndex = -1;

  @override
  void initState() {
    print("<<<<<<< MenuBasketDetailScreen >>>>>>>");
    _basketId = widget.basketId;
    _getBasketDetail();
    _getBasketHistoryList();
    _onScanPressed();
    super.initState();
  }

  Future<void> _onScanPressed() async {
    print("onscan pressed ");
    if (Platform.isAndroid) {
      print("is andriod");
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      print(statuses);
      print(_isLoading1);
      if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
          statuses[Permission.bluetoothConnect] != PermissionStatus.granted) {
        return;
      }
    }

    setState(() => _isLoading1 = true);
    _bluePrintPos.scan().then((List<BlueDevice> devices) async {
      print("Scanning  >> ");
      if (devices.isNotEmpty) {
        setState(() {
          _blueDevices = devices;
          _isLoading1 = false;
        });
      } else {
        setState(() => _isLoading1 = false);
      }
      print(_isLoading1);
      await _onSelectDevice(0);
    });
  }

  void _onDisconnectDevice() {
    _bluePrintPos.disconnect().then((ConnectionStatus status) {
      if (status == ConnectionStatus.disconnect) {
        setState(() {
          _selectedDevice = null;
        });
      }
    });
  }

  void _onSelectDevice(int index) {
    print("_onselectDevice");
    setState(() {
      _isLoading = true;
      _loadingAtIndex = index;
    });
    final BlueDevice blueDevice = _blueDevices[index];
    _bluePrintPos.connect(blueDevice).then((ConnectionStatus status) async {
      if (status == ConnectionStatus.connected) {
        print("connected >>");
        await _onPrintReceipt();
        setState(() => _selectedDevice = blueDevice);
      } else if (status == ConnectionStatus.timeout) {
        _onDisconnectDevice();
      } else {
        if (kDebugMode) {
          print('$runtimeType - something wrong');
        }
      }
      setState(() => _isLoading = false);
    });
  }

  Future<void> _onPrintReceipt() async {
    print("print receipt >> ");
    /// Example for Print Image
    final ByteData logoBytes = await rootBundle.load(
      'assets/logo.jpg',
    );

    /// Example for Print Text
    final ReceiptSectionText receiptText = ReceiptSectionText();
    receiptText.addImage(
      base64.encode(Uint8List.view(logoBytes.buffer)),
      width: 300,
    );
    receiptText.addSpacer();
    receiptText.addText(
      'EXCEED YOUR VISION',
      size: ReceiptTextSizeType.medium,
      style: ReceiptTextStyleType.bold,
    );
    receiptText.addText(
      'MC Koo',
      size: ReceiptTextSizeType.small,
    );
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText('Time', '04/06/22, 10:30');
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      'Apple 4pcs',
      '\$ 10.00',
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      'TOTAL',
      '\$ 10.00',
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      'Payment',
      'Cash',
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.normal,
    );
    receiptText.addSpacer(count: 2);

    await _bluePrintPos.printReceiptText(receiptText);

    /// Example for print QR
    await _bluePrintPos.printQR('https://www.google.com/', size: 250);

    /// Text after QR
    final ReceiptSectionText receiptSecondText = ReceiptSectionText();
    receiptSecondText.addText('Powered by Google',
        size: ReceiptTextSizeType.small);
    receiptSecondText.addSpacer();
    await _bluePrintPos.printReceiptText(receiptSecondText, feedCount: 1);
  }
  _getBasketDetail() async {
    try {
      setState(() {
        _isLoading = true;
      });
      _basketDetailModel =
          await _basketDetailApi.basketDetailAPI(context, basketId: _basketId);

      setState(() {
        _isLoading = false;
      });
    } catch (err, s) {
      print('ERROR MenuBasketDetailScreen _getBasketDetail >>>> $err');
      FirebaseCrashlytics.instance.recordError(err, s,
          reason: "ERROR  MenuBasketDetailScreen _getBasketDetail");
    }
  }

  _getBasketHistoryList() async {
    try {
      _basketHistoryListModel =
          await _basketHistoryListApi.basketHistoryListAPI(context,
              basketId: _basketId, status: _statusValue.ALL);
    } catch (err, s) {
      print('ERROR MenuBasketDetailScreen _getBasketHistoryList >>>> $err');
      FirebaseCrashlytics.instance.recordError(err, s,
          reason: "ERROR  MenuBasketDetailScreen _getBasketHistoryList");
    }
  }

  @override
  Widget build(BuildContext context) {
    // print(_basketDetailModel.data.orderType);
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: AppColors.white,
          automaticallyImplyLeading: false,
          centerTitle: false,
          title: Text(
            "Order Details",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color.fromARGB(255, 116, 138, 157),
              fontWeight: FontWeight.w400,
              fontSize: 25,
              letterSpacing: -0.42,
            ),
          ),
          leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: Color.fromARGB(255, 116, 138, 157),
              ),
              tooltip: "Back",
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => MainScreen()));
              }),
        ),
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(15),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Center(
                      child: _buildStatus(),
                    ),
                    SizedBox(height: 30.0),

                    /// total item
                    Row(
                      children: [
                        Text(
                          "Your Order",
                          style: TextStyle(
                            color: AppColors.titleTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        Spacer(),
                        Text(
                          _getTotalItems() > 1
                              ? "${_getTotalItems()} Items"
                              : "${_getTotalItems()} Item",
                          style: TextStyle(
                            color: AppColors.titleTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15.0),

                    Scrollbar(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                            color: Colors.transparent,
                            margin: EdgeInsets.only(bottom: 10.0),
                            padding: EdgeInsets.only(bottom: 5.0),
                            child: Card(
                              elevation: 0.5,
                              child: Container(
                                  decoration: new BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: new BorderRadius.only(
                                          topLeft: const Radius.circular(10.0),
                                          topRight:
                                              const Radius.circular(10.0))),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      minRadius: 20,
                                      maxRadius: 25,
                                      backgroundImage: NetworkImage(
                                          "${_textValues.imageURL}${_basketDetailModel.data.items[index].item.image}"),
                                    ),
                                    title: RichText(
                                      text: TextSpan(children: [
                                        TextSpan(
                                          text:
                                              "${_basketDetailModel.data.items[index].item.name} ",
                                          style: TextStyle(
                                            color: AppColors.titleTextColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 17,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _basketDetailModel.data
                                                      .items[index].item.unit ==
                                                  _textValues.na
                                              ? ""
                                              : "(${UnitService().getUnitName(_basketDetailModel.data.items[index].item.unit)})",
                                          style: TextStyle(
                                            color: AppColors.titleTextColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        )
                                      ]),
                                    ),
                                    subtitle: Text(
                                      "x ${_basketDetailModel.data.items[index].item.quantity}",
                                      style: TextStyle(
                                        color: AppColors.titleTextColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                    trailing: Text(
                                      "${CountryDataConfig().currencyIcon} ${_basketDetailModel.data.items[index].item.price.roundNumber(2)}",
                                      style: TextStyle(
                                        color: AppColors.titleTextColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                  )),
                            ),
                          );
                        },
                        itemCount: _basketDetailModel.data.items.length,
                      ),
                    ),

                    SizedBox(height: 15.0),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bill Details",
                          style: TextStyle(
                            color: AppColors.titleTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 15.0),

                        /// sub-total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Sub-Total",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: AppColors.subTitleTextColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            Spacer(),
                            Text(
                              "${CountryDataConfig().currencyIcon} ${_basketDetailModel.data.subTotal.toStringAsFixed(2)}",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: AppColors.titleTextColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15.0),

                        /// discount
                        ///

                        _buildTotalDiscount(),
                        _basketDetailModel.data.discount == 0
                            ? SizedBox()
                            : SizedBox(height: 15.0),

                        /// delivery fee
                        _basketDetailModel.data.orderType !=
                                    _statusValue.HOME_DELIVERY ||
                                _basketDetailModel.data.orderType ==
                                    _statusValue.Dine_In ||
                                _basketDetailModel.data.orderType ==
                                    _statusValue.TAKE_AWAY
                            ? SizedBox()
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Delivery fee",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: AppColors.subTitleTextColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    "${CountryDataConfig().currencyIcon} ${_basketDetailModel.data.deliveryFee.toStringAsFixed(2)}",
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: AppColors.titleTextColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                        _basketDetailModel.data.orderType !=
                                _statusValue.HOME_DELIVERY
                            ? SizedBox()
                            : SizedBox(height: 15.0),

                        //Packing fee
                        _basketDetailModel.data.orderType !=
                                    _statusValue.HOME_DELIVERY &&
                                _basketDetailModel.data.orderType !=
                                    _statusValue.Dine_In &&
                                _basketDetailModel.data.packingCharge != null
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Packing fee",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: AppColors.subTitleTextColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    "${CountryDataConfig().currencyIcon} ${_basketDetailModel.data.packingCharge.toStringAsFixed(2)}",
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: AppColors.titleTextColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox(),
                        _basketDetailModel.data.orderType ==
                                _statusValue.TAKE_AWAY
                            ? SizedBox(
                                height: 10,
                              )
                            : SizedBox(),

                        /// tax
                        _buildTotalTax(),
                        SizedBox(height: 15.0),

                        /// total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Total",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: AppColors.subTitleTextColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Spacer(),
                            Text(
                              "${CountryDataConfig().currencyIcon}  ${_basketDetailModel.data.basketTotal.toStringAsFixed(2)}",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: AppColors.titleTextColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 15.0),
                      child: Divider(
                        height: 0,
                      ),
                    ),

                    /// order details
                    Text(
                      "Order Details",
                      style: TextStyle(
                        color: AppColors.titleTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),

                    SizedBox(
                      height: 15.0,
                    ),
                    Text(
                      "Token Number",
                      style: TextStyle(
                        color: AppColors.subTitleTextColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      "${_basketDetailModel.data.tokenNo}",
                      style: TextStyle(
                        color: AppColors.titleTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Text(
                      "Ordered on",
                      style: TextStyle(
                        color: AppColors.subTitleTextColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      "${_dateService.formatDate(_basketDetailModel.data.audit?.created?.on)}",
                      style: TextStyle(
                        color: AppColors.titleTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Text(
                      "Order type",
                      style: TextStyle(
                        color: AppColors.subTitleTextColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      "${_basketDetailModel.data.orderType}",
                      style: TextStyle(
                        color: AppColors.titleTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    _basketDetailModel.data.orderType ==
                            BasketOrderType.HomeDelivery.name.toUpperCase()
                        ? _customerDetailsWidget()
                        : new SizedBox()
                  ],
                ),
        ),
        bottomNavigationBar: _isLoading == true
            ? SizedBox()
            : "${_basketDetailModel.data.orderType}" == _statusValue.Dine_In
                // "${_basketDetailModel.data.status}" == _statusValue.ACCEPTED ||
                // "${_basketDetailModel.data.status}" == _statusValue.ORDER_PLACED ||
                //         "${_basketDetailModel.data.orderType}" != _statusValue.HOME_DELIVERY
                ? Row(
                    children: [
                      Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width / 2,
                        child: SquareFlatButton(
                          buttonColor: AppColors.green,
                          buttonName: "Done",
                          iconName: null,
                          onClicked: () {
                            if (_isLoading == false) {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MainScreen()));
                            }
                          },
                        ),
                      ),
                      Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width / 2,
                        child: SquareRaisedButton(
                          buttonColor: AppColors.blueButtonColor,
                          buttonName: "Order More",
                          iconName: null,
                          onClicked: () {
                            if (_isLoading == false) {
                              _handleEditOrder();
                            }
                          },
                        ),
                      ),
                    ],
                  )
                :
                //FOR HOMEDELIVERY and TAKEAWAY order navigate to home screen
                Container(
                    height: 50,
                    margin: EdgeInsets.only(left: 13, right: 13),
                    width: MediaQuery.of(context).size.width / 2.8,
                    child: RoundedRaisedButton(
                      buttonColor: AppColors.blueButtonColor,
                      buttonName: "BACK TO HOME",
                      iconName: null,
                      onClicked: () {
                        if (_isLoading == false) {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MainScreen()));
                        }
                      },
                    ),
                  ),
        // TODO do not delete it. timer may be used in future
        //   floatingActionButton: _isLoading == true
        //       ? SizedBox()
        //       : "${_basketDetailModel.data.status}" == _statusValue.ACTIVE ||
        //               "${_basketDetailModel.data.status}" == _statusValue.FINISHED
        //           ? FloatingActionButton(
        //               onPressed: () {
        //                 if (_isLoading == false) _showTimer();
        //               },
        //               child: Icon(Icons.timer_outlined),
        //             )
        //           : SizedBox(),
      ),
      onWillPop: () => onWillPops(context),
    );
  }

  /// onBack pressed function
  Future<bool> onWillPops(BuildContext context) async {
    Navigator.of(context).pop();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => MainScreen()));
    return true;
  }

  /// this will add the basket order to the temporary basket provider
  _handleEditOrder() {
    final basketProvider =
        Provider.of<BasketAndTableProvider>(context, listen: false);
    basketProvider.cleanTempBasketList();
    var orderType;
    if (_basketDetailModel.data.orderType == StatusValue().HOME_DELIVERY) {
      orderType = BasketOrderType.HomeDelivery;
    } else if (_basketDetailModel.data.orderType == StatusValue().Dine_In) {
      orderType = BasketOrderType.DineIn;
    } else if (_basketDetailModel.data.orderType == StatusValue().TAKE_AWAY) {
      orderType = BasketOrderType.TakeAway;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MenuScreen(
                  isUpdateOrder: true,
                  basketId: widget.basketId,
                  storeId: _basketDetailModel.data.store.id,
                  tableNo:
                      _basketDetailModel.data.orderType == _statusValue.Dine_In
                          ? _basketDetailModel.data.table[0].tableNo
                          : 0,
                  orderType: orderType,
                )));
  }

  /// to find the total item in the order
  num _getTotalItems() {
    var total = 0;
    _basketDetailModel.data.items.forEach((element) {
      total += element.item.quantity;
    });
    return total;
  }

  /// customer details. when order is not Dine in
  _customerDetailsWidget() {
    return _basketDetailModel.data.orderType == _statusValue.Dine_In
        ? SizedBox(
            height: 15.0,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 15.0),
                child: Divider(
                  height: 0,
                ),
              ),
              SizedBox(height: 15.0),
              Text(
                "Customer Details",
                style: TextStyle(
                  color: AppColors.titleTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              SizedBox(
                height: 15.0,
              ),
              Text(
                "Name",
                style: TextStyle(
                  color: AppColors.subTitleTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              Text(
                _basketDetailModel.data?.clientDetails?.name == null ||
                        _basketDetailModel.data?.clientDetails?.name == ''
                    ? "Not Available"
                    : "${_basketDetailModel.data.clientDetails.name}",
                style: TextStyle(
                  color: AppColors.titleTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              SizedBox(
                height: 15.0,
              ),
              Text(
                "Mobile",
                style: TextStyle(
                  color: AppColors.subTitleTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              Text(
                _basketDetailModel.data?.clientDetails?.name == null ||
                        _basketDetailModel.data?.clientDetails?.name == ''
                    ? "Not Available"
                    : "${_basketDetailModel.data.clientDetails.phone}",
                style: TextStyle(
                  color: AppColors.titleTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              SizedBox(
                height: 15.0,
              ),
              Text(
                "Address",
                style: TextStyle(
                  color: AppColors.subTitleTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              Text(
                _basketDetailModel.data?.clientDetails?.name == null ||
                        _basketDetailModel.data?.clientDetails?.name == ''
                    ? "Not Available"
                    : "${_basketDetailModel.data.clientDetails.address}",
                style: TextStyle(
                  color: AppColors.titleTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              SizedBox(
                height: 15.0,
              ),
            ],
          );
  }

  /// total discount
  Widget _buildTotalDiscount() {
    _totalDiscount = 0;
    _basketDetailModel.data.items.forEach((element) {
      _totalDiscount = _totalDiscount +
          (element.item.quantity * element.price.discount.total);
    });
    return _basketDetailModel.data.discount == 0
        ? SizedBox()
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Discount",
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: AppColors.subTitleTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              Spacer(),
              Text(
                "${CountryDataConfig().currencyIcon} ${_totalDiscount.toStringAsFixed(2)}",
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.titleTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          );
  }

  /// total tax
  Widget _buildTotalTax() {
    _totalTax = 0;
    var taxInclusive = false;
    _basketDetailModel.data.items.forEach((element) {
      taxInclusive = element.price.tax.items[0].taxInclusive;
      _totalTax += element.price.tax.total;
    });
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          taxInclusive
              ? "${_textValues.totalTax} \n${_textValues.inclInSubTotal}"
              : "${_textValues.totalTax}",
          textAlign: TextAlign.left,
          style: TextStyle(
            color: AppColors.subTitleTextColor,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        InkWell(
          onTap: () {
            _showModalSheetForItemTax(context);
          },
          child: Icon(
            Icons.info_outline,
            color: AppColors.subTitleTextColor,
          ),
        ),
        Spacer(),
        Text(
          "${CountryDataConfig().currencyIcon} ${_totalTax.toStringAsFixed(2)}",
          textAlign: TextAlign.right,
          style: TextStyle(
            color: AppColors.titleTextColor,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  _showTimer() {
    showModalBottomSheet(
        context: context,
        elevation: 0,
        barrierColor: Colors.black.withAlpha(100),
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Container(
            color: Colors.transparent,
            child: Container(
                height: MediaQuery.of(context).size.height / 1.4,
                padding: EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.all(const Radius.circular(5.0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Preparation Time",
                          style: TextStyle(
                            color: AppColors.titleTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.close)),
                      ],
                    ),
                    SizedBox(height: 15.0),
                    Scrollbar(
                      isAlwaysShown: true,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          return _MenuOrderTimerWidget(
                            basketItems: _basketHistoryListModel.data[index],
                          );
                        },
                        itemCount: _basketHistoryListModel.data.length,
                      ),
                    ),
                  ],
                )),
          );
        });
  }

  Widget _buildStatus() {
    if (_basketDetailModel.data.status == _statusValue.ACTIVE) {
      return Text(
        "Order is preparing in the kitchen.",
        style: TextStyle(
          color: AppColors.green,
          fontWeight: FontWeight.w500,
          fontSize: 15,
          letterSpacing: 1.4,
        ),
      );
    } else if (_basketDetailModel.data.status == _statusValue.REJECTED) {
      return Text(
        "This order is ${_basketDetailModel.data.status.capitalizeFirst()}",
        style: TextStyle(
          color: AppColors.red,
          fontWeight: FontWeight.w500,
          fontSize: 15,
          letterSpacing: 1.4,
        ),
      );
    } else if (_basketDetailModel.data.status == _statusValue.CONFIRMED) {
      return Text(
        "This order is ${_basketDetailModel.data.status.capitalizeFirst()}",
        style: TextStyle(
          color: AppColors.blue,
          fontWeight: FontWeight.w500,
          fontSize: 15,
          letterSpacing: 1.4,
        ),
      );
    } else if (_basketDetailModel.data.status == _statusValue.ORDER_PLACED) {
      return Text(
        "Order Placed",
        style: TextStyle(
          color: AppColors.blue,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 1.4,
        ),
      );
    } else {
      return Text(
        "This order is ${_basketDetailModel.data.status.capitalizeFirst()}",
        style: TextStyle(
          color: AppColors.focusColor,
          fontWeight: FontWeight.w500,
          fontSize: 15,
          letterSpacing: 1.4,
        ),
      );
    }
  }

  /// modal class to show tax of individual item
  _showModalSheetForItemTax(BuildContext context) {
    showDialog(
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: AppColors.white),
            padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DataTable(
                    dataRowHeight: 75,
                    columns: [
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Rate")),
                      DataColumn(label: Text("Amount")),
                    ],
                    rows: _basketDetailModel.data.items
                        .map((e) => DataRow(cells: [
                              DataCell(RichText(
                                maxLines: 3,
                                text: TextSpan(children: [
                                  TextSpan(
                                    text: e.item.name.length < 18
                                        ? "${e.item.name}"
                                        : "${e.item.name.substring(0, 17)}...",
                                    style: TextStyle(
                                      color: AppColors.titleTextColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                      overflow: TextOverflow.clip,
                                    ),
                                  ),
                                  TextSpan(
                                    text: e.item.unit == TextValues().na
                                        ? ""
                                        : "\n${UnitService().getUnitName(e.item.unit)}",
                                    style: TextStyle(
                                      color: AppColors.subTitleTextColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13.5,
                                    ),
                                  )
                                ]),
                              )),
                              DataCell(
                                Text("${e.price.tax.items[0].rate ?? ""}%"),
                              ),
                              DataCell(
                                Text(
                                    "${CountryDataConfig().currencyIcon}${e.price.tax.items[0].amount.roundNumber(2)} "),
                              ),
                            ]))
                        .toList()),
                TextButton(
                    child: Text("${_textValues.close}",
                        style: TextStyle(fontSize: 17.0)),
                    onPressed: () {
                      /// close modal
                      Navigator.of(context).pop();
                    }),
              ],
            ),
          ),
        );
      },
      context: context,
    );
  }
}

class _MenuOrderTimerWidget extends StatefulWidget {
  final BasketHistoryListData basketItems;

  const _MenuOrderTimerWidget({Key key, this.basketItems}) : super(key: key);

  @override
  _MenuOrderTimerWidgetState createState() => _MenuOrderTimerWidgetState();
}

class _MenuOrderTimerWidgetState extends State<_MenuOrderTimerWidget> {
  BasketHistoryListData _basketItems = new BasketHistoryListData();
  final interval = const Duration(seconds: 1);
  Timer time;

  bool _showTimer = false;

  int timerMaxSeconds = 60;
  int currentSeconds = 0;

  @override
  void initState() {
    _basketItems = widget.basketItems;
    var t1 = DateTime.parse(_basketItems.audit?.modified?.on);
    var t2 = DateTime.now();
    var startTime = t1.hour * 3600 + t1.minute * 60 + t1.second;
    var endTime = t2.hour * 3600 + t2.minute * 60 + t2.second;
    var actualTime = endTime - startTime;
    var preparingTime = int.parse(_basketItems.preparingTime);
    var remainingTime = 0;

    if (actualTime >= preparingTime) {
      remainingTime = 0;
    } else {
      remainingTime = preparingTime - actualTime;
    }

    timerMaxSeconds = remainingTime;

    if (!timerMaxSeconds.isNegative) {
      _showTimer = true;
      _startTimeout();
    }
    super.initState();
  }

  @override
  void dispose() {
    time.cancel();
    super.dispose();
  }

  String get timerText =>
      '${((timerMaxSeconds - currentSeconds) ~/ 60).toString().padLeft(2, '0')}: ${((timerMaxSeconds - currentSeconds) % 60).toString().padLeft(2, '0')}';

  _startTimeout() {
    var duration = interval;
    time = new Timer.periodic(duration, (timer) {
      setState(() {
        currentSeconds = timer.tick;
      });
      if (timer.tick >= timerMaxSeconds) {
        timer.cancel();
        _showTimer = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // leading: CircleAvatar(
      //   minRadius: 20,
      //   maxRadius: 25,
      //   backgroundImage:
      //       NetworkImage("${TextValues().IMAGE_URL}${_basketItems.}"),
      // ),
      title: Text(
        "${_basketItems.item.name.toUpperCase()}",
        style: TextStyle(
          color: AppColors.titleTextColor,
          fontWeight: FontWeight.w500,
          fontSize: 17,
        ),
      ),
      subtitle: Text(
        _basketItems.unit == "NA"
            ? "Quantity x ${_basketItems.quantity}"
            : "${_basketItems.unit} x ${_basketItems.quantity}",
        style: TextStyle(
          color: AppColors.titleTextColor,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: _buildTimerText(),
    );
  }

  Widget _buildTimerText() {
    if (_basketItems.status == StatusValue().ACTIVE ||
        _basketItems.status == StatusValue().PREPARING ||
        _basketItems.status == StatusValue().FINISHED) {
      return Text(
        _showTimer ? "$timerText" : "Preparing, wait a little.",
        softWrap: true,
        maxLines: 2,
        style: TextStyle(
          color: AppColors.blue,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      );
    } else if (_basketItems.status == StatusValue().PREPARED) {
      return Text(
        "Will be served soon",
        softWrap: true,
        maxLines: 2,
        style: TextStyle(
          color: AppColors.blue,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      );
    } else if (_basketItems.status == StatusValue().SERVED) {
      return Text(
        "",
        softWrap: true,
        maxLines: 2,
        style: TextStyle(
          color: AppColors.blue,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      );
    } else {
      return Text(
        "00: 00",
        softWrap: true,
        maxLines: 2,
        style: TextStyle(
          color: AppColors.blue,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      );
    }
  }
}
